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

	/* import database : open;
	import std.string : representation;
	import std.stdio;
	auto db = open("testdb");
	db.get("key!".representation.dup).writeln;
	db.put("key!".representation.dup, "value.".representation.dup);
	db.close(); */

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
