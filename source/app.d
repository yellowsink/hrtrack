import vibe.vibe;

void main()
{
	auto settings = new HTTPServerSettings;
	settings.port = 8080;
	settings.bindAddresses = ["::1", "127.0.0.1"];
	settings.sessionStore = new MemorySessionStore; // should I be storing this in Rocks instead? Probably fine.

	auto listener = listenHTTP(
		settings,
		new URLRouter()
			.registerRestInterface(new Api)
			.get("*", serveStaticFiles("./public/"))
	);

	scope (exit) listener.stopListening();

	runApplication();
}

@path("/")
interface IApi
{

}

class Api : IApi
{
	private
	{
		// session variables go here
	}
}
