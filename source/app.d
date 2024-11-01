import vibe.vibe;

import sessionstore : ExpiringMemorySessionStore;

import types : AuthedUserSession;

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

	/* import storage : encrypt, decrypt;
	import std.string : representation, assumeUTF;
	import std.stdio;

	ubyte[256/8] key = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31];
	auto plaintext = "hello there how are you doing today".representation;
	auto encrypted = encrypt(key, plaintext);
	writeln(encrypted);
	writeln(decrypt(key, encrypted).assumeUTF); */

	runApplication();
}

class Api
{
	private
	{
		// stores the user's name and encryption key in the session
		SessionVar!(AuthedUserSession, "user") authedUser;
	}


}
