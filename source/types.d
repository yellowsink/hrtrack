alias RawAESKey = ubyte[256/8];

struct AuthedUserSession
{
	ulong id;
	RawAESKey key;
}
