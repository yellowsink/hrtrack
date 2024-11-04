import std.base64 : B64 = Base64URLNoPadding;
import std.bitmanip : littleEndianToNative, nativeToLittleEndian;

private T[L] dynToStatic(ulong L, T)(T[] dyn)
{
	import std.exception : enforce;

	T[L] dst;
	enforce(dyn.length == L);
	dst[] = dyn[];
	return dst;
}

alias RawAESKey = ubyte[256/8];

/// the data stored when a user is authenticated: their id and user data key
struct AuthedUserSession
{
	ulong id;
	RawAESKey userDataKey;
}

/// the data given to us by the client for an access key authentication attempt: their id and access key
struct AccessKeyAuthPair
{
	ulong id;
	RawAESKey accessKey;
}

/// the same as AccessKeyAuthPair but for sending to the client
struct ApiAccessKeyAuthPair
{
	char[] id;
	char[] accessKey;

	this(AccessKeyAuthPair ap)
	{
		id = B64.encode(ap.id.nativeToLittleEndian);
		accessKey = B64.encode(ap.accessKey);
	}

	this(char[] id, char[] ap)
	{
		this.id = id;
		this.accessKey = ap;
	}

	AccessKeyAuthPair decode()
	{
		return AccessKeyAuthPair(
			B64.decode(id).dynToStatic!(ulong.sizeof).littleEndianToNative!ulong,
			B64.decode(accessKey).dynToStatic!32
		);
	}
}
