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

bool check_hash(const Hash hash, const ubyte[] raw)
{
	import secured.hash : hash_verify_ex, HashAlgorithm;

	return hash_verify_ex(hash[], raw, HashAlgorithm.SHA3_256);
}

Hash hash_salted(const ubyte[] raw)
{
	import secured.hash : hash_ex, HashAlgorithm;

	auto salt = rand!8;

	auto hashesd = hash_ex(salt ~ raw, HashAlgorithm.SHA3_224);
	assert(hashesd.length == 24);

	Hash buf;
	buf[0 .. 8] = salt[];
	buf[8 .. $] = hashesd[];
	return buf;
}

bool check_hash_salted(const Hash hash, const ubyte[] raw)
{
	import secured.hash : hash_verify_ex, HashAlgorithm;

	auto salt = hash[0 .. 8];

	return hash_verify_ex(hash[8 .. $], salt ~ raw, HashAlgorithm.SHA3_224);
}

unittest
{
	auto h1 = hash_salted([1, 2, 3, 4]);
	auto h2 = hash_salted([1, 2, 3, 4]);

	assert(h1[] != h2[], "hashes were the same");
	assert(check_hash_salted(h1, [1, 2, 3, 4]), "hash 1 did not verify");
	assert(check_hash_salted(h2, [1, 2, 3, 4]), "hash 2 did not verify");
}

unittest
{
	auto h1 = hash([1, 2, 3, 4]);
	auto h2 = hash([1, 2, 3, 4]);

	assert(h1[] == h2[], "hashes were not the same");
	assert(check_hash(h1, [1, 2, 3, 4]), "hash did not verify");
}

unittest
{
	auto key = rand!RawAESKey();
	auto data = rand!2048();

	auto crypted = encrypt(key, data);

	auto decrypted = decrypt(key, crypted);

	assert(data == decrypted, "AES did not round trip");
}
