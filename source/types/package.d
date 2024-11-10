module types;

public import types.domain;

import std.base64 : B64 = Base64URLNoPadding;
import std.bitmanip : bigEndianToNative, nativeToBigEndian;

private T[L] dynToStatic(ulong L, T)(T[] dyn)
{
	import std.exception : enforce;

	T[L] dst;
	enforce(dyn.length == L);
	dst[] = dyn[];
	return dst;
}

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
		id = B64.encode(ap.id.nativeToBigEndian);
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
			B64.decode(id).dynToStatic!(ulong.sizeof)
				.bigEndianToNative!ulong,
				B64.decode(accessKey).dynToStatic!32
		);
	}
}
