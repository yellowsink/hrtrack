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
