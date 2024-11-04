import vibe.vibe;

import sessionstore : ExpiringMemorySessionStore;

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

		static ubyte[N] rand(ulong N)()
		{
			import secured.random : random;

			ubyte[N] buf;
			buf[] = random(N);
			return buf;
		}

		static T rand(T)()
		{
			return *(cast(T*) rand!(T.sizeof));
		}
	}

	string index() { return ""; }

	// step 1 of the signup flow: generate provisional credentials
	Json getProvisionalCreds()
	{
		import std.base64 : Base64URLNoPadding;

		auto ap = AccessKeyAuthPair(rand!ulong, rand!RawAESKey);
		provisionalCreds = ap;

		return serializeToJson(ApiAccessKeyAuthPair(ap));
	}

	string postCreateAccount(char[] id, char[] accessKey)
	{
		auto creds = ApiAccessKeyAuthPair(id, accessKey).decode();

		if (creds.id != provisionalCreds.id || creds.accessKey != provisionalCreds.accessKey)
		{
			status(HTTPStatus.badRequest);
			return "Invalid provisional credentials provided";
		}

		request.session.remove("provisionalCreds");

		// TODO: create account

		return "Created account";
	}
}
