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
	settings.bindAddresses = ["::1", "127.0.0.1"];
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
	}

	string index() { return ""; }

	// step 1 of the signup flow: generate provisional credentials
	Json getProvisionalCreds()
	{
		AccessKeyAuthPair ap;
		do
		{
			ap = AccessKeyAuthPair(rand!ulong, rand!RawAESKey);
		} while (database.hasUser(ap.id));

		provisionalCreds = ap;

		return serializeToJson(ApiAccessKeyAuthPair(ap));
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

		return "Created account";
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

			status(HTTPStatus.ok);
			response.contentType = "application/json";
			return serializeToJsonString(userData.get);
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
		return "";
	}
}
