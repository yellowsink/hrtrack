module crypt;

import types : RawAESKey, Hash;

ubyte[N] rand(ulong N)()
{
	import secured.random : random;

	ubyte[N] buf;
	buf[] = random(N);
	return buf;
}

T rand(T)()
{
	auto bytes = rand!(T.sizeof)();
	return *(cast(T*) &bytes);
}

ubyte[] encrypt(const RawAESKey rkey, const ubyte[] payload)
{
	import secured.symmetric : initializeSymmetricKey, encrypt;

	auto key = initializeSymmetricKey(rkey);
	auto encrypted = encrypt(key, payload);

	return (encrypted.iv ~ encrypted.cipherText ~ encrypted.authTag).dup;
}

// note that secured authenticates the encryption for us,
// so if you plug in the wrong key, you get a CryptographicException, not garbage data.
ubyte[] decrypt(const RawAESKey rkey, const ubyte[] cipher)
{
	import secured.symmetric : initializeSymmetricKey, EncryptedData, decrypt;

	auto key = initializeSymmetricKey(rkey);
	auto encrypted = EncryptedData(cipher, 12, 16);

	return decrypt(key, encrypted);
}

Hash hash(const ubyte[] raw)
{
	import secured.hash : hash_ex, HashAlgorithm;

	Hash buf;
	buf[] = hash_ex(raw, HashAlgorithm.SHA3_256);
	return buf;
}

// performs a constant-time check for extra security.
bool check_hash(const Hash hash, const ubyte[] raw)
{
	import secured.hash : hash_verify_ex, HashAlgorithm;

	return hash_verify_ex(hash[], raw, HashAlgorithm.SHA3_256);
}
