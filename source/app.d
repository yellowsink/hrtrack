import vibe.vibe;

import secured.util : CryptographicException;

import sessionstore : ExpiringMemorySessionStore;

import crypt;
import storage;
import types;

void main()
{
	auto settings = new HTTPServerSettings;
	settings.port = 8080;
	settings.bindAddresses = ["::"];
	settings.sessionStore = new ExpiringMemorySessionStore;

	auto listener = listenHTTP(
		settings,
		new URLRouter()
			.registerWebInterface(new Api)
			.get("*", serveStaticFiles("./public/"))
	);

	scope (exit) listener.stopListening();

	runApplication();
}

class Api
{
	private
	{
		// stores the user's name and encryption key in the session
		SessionVar!(AuthedUserSession, "user") authedUser;

		// stores the provisional auth details for the user signup flow
		SessionVar!(AccessKeyAuthPair, "provisionalCreds") provisionalCreds;

		bool sessionHas(string key)
		{
			return request.session && request.session.isKeySet(key);
		}

		void delayedRedirect(int timeout, string dest)
		{
			header("Refresh", timeout.to!string ~ "; url=" ~ dest);
			response.writeBody("You were logged out. Redirecting in " ~ timeout.to!string ~ " seconds...", "text/html");
		}
	}

	void index() { render!"index.dt"; }

	void getDashboard()
	{
		if (!sessionHas("user"))
		{
			status(HTTPStatus.unauthorized);
			delayedRedirect(5, "/");
			return;
		}

		auto isOnboarding = "onboard" in request.query;

		render!("dashboard.dt", isOnboarding);
	}

	// step 1 of the signup flow: generate provisional credentials
	void getAccountPreflight()
	{
		AccessKeyAuthPair ap;
		do
		{
			ap = AccessKeyAuthPair(rand!ulong, rand!RawAESKey);
		} while (database.hasUser(ap.id));

		provisionalCreds = ap;

		auto apiCreds = ApiAccessKeyAuthPair(ap);

		render!("account_preflight.dt", apiCreds);
	}

	// step 2 of the signup flow: as long as the user provides correct provisional credentials, create an account
	string postCreateAccount(char[] id, char[] accessKey)
	{
		// prevent someone sending AAAAAAAAAAA, AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA etc
		if (!request.session || !request.session.isKeySet("provisionalCreds"))
		{
			status(HTTPStatus.unauthorized);
			return "You must access /provisional_creds before attempting to create an account";
		}

		auto creds = ApiAccessKeyAuthPair(id, accessKey).decode();

		if (creds.id != provisionalCreds.id || creds.accessKey != provisionalCreds.accessKey)
		{
			status(HTTPStatus.unauthorized);
			return "You must return the same credentials as previously provided to you";
		}

		request.session.remove("provisionalCreds");

		authedUser = database.createUser(creds.id, creds.accessKey);

		redirect("/dashboard?onboard", 303);
		return "";
	}

	string postLogin(char[] id, char[] accessKey)
	{
		auto creds = ApiAccessKeyAuthPair(id, accessKey).decode();

		// we fail more than we succeed lmao
		status(HTTPStatus.unauthorized);

		// catch incorrect decryptions keys, this is how we detect incorrect creds
		try
		{
			// get user data key from the database
			auto udKey = database.getUserDataKey(creds.accessKey);
			if (udKey.isNull)
				return "incorrect user ID or access key";

			// now, get user data
			auto userData = database.getUserById(creds.id, udKey.get);
			if (userData.isNull)
				return "incorrect user ID or access key";

			// yay! we're okay. now set our session and return.
			authedUser = AuthedUserSession(creds.id, udKey.get);

			redirect("/dashboard", 303);
			return "";
		}
		catch (CryptographicException)
		{
			return "incorrect user ID or access key";
		}
	}

	string postLogout()
	{
		if (!request.session || !request.session.isKeySet("user"))
		{
			status(HTTPStatus.badRequest);
			return "You are not logged in";
		}

		request.session.remove("user");
		redirect("/", 303);
		return "";
	}

	// DEBUG ONLY, this whole function is STUPID insecure
	debug
	Json getDumpDatabase(char[] accessKey) // key for decryption
	{
		import std.bitmanip : bigEndianToNative, nativeToBigEndian;

		alias B64 = Base64URLNoPadding;

		ubyte[32] realAKey;
		realAKey[] = B64.decode(accessKey);

		// get user data key
		auto udKey = database.getUserDataKey(realAKey).get;

		// try and decrypt everything i guess lmao
		auto db = database;
		auto iter = db.iter();

		Json ret = Json.emptyObject;

		foreach (key, _; iter)
		{
			try {
				auto key = iter.key;
				auto kt = cast(KeyType) key[0];

				final switch (kt) with (KeyType)
				{
					case UserDataById:
						ubyte[ulong.sizeof] idk;
						idk[] = key[1..$];
						auto id = idk.bigEndianToNative!ulong;
						ret[cast(immutable) (kt.to!string ~ "_" ~ B64.encode(key[1..$]))] = serializeToJson(db.getUserById(id, udKey));
						break;

					case UDKeyByAccessKey:
						Hash h;
						h[] = key[1..$];

						if (check_hash(h, realAKey))
							ret[cast(immutable) (kt.to!string ~ "_" ~ B64.encode(h))] = serializeToJson(db.getUserDataKey(realAKey));
				}
			}
			catch (Exception e)
			{
				// this is for debugging anyway
				logDebug(e.to!string);
			}
		}

		return ret;
	}
}
