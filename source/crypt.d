module crypt;

import types : RawAESKey;

ubyte[N] rand(ulong N)()
{
	import secured.random : random;

	ubyte[N] buf;
	buf[] = random(N);
	return buf;
}

T rand(T)()
{
	return *(cast(T*) rand!(T.sizeof));
}

ubyte[] encrypt(const RawAESKey rkey, const ubyte[] payload) @safe
{
	import secured.symmetric : initializeSymmetricKey, encrypt;

	auto key = initializeSymmetricKey(rkey);
	auto encrypted = encrypt(key, payload);

	return (encrypted.iv ~ encrypted.cipherText ~ encrypted.authTag).dup;
}

ubyte[] decrypt(const RawAESKey rkey, const ubyte[] cipher) @safe
{
	import secured.symmetric : initializeSymmetricKey, EncryptedData, decrypt;

	auto key = initializeSymmetricKey(rkey);
	auto encrypted = EncryptedData(cipher, 12, 16);

	return decrypt(key, encrypted);
}
