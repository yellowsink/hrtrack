// encrypted data storage utilities

import rocksdb;

import types : RawAESKey;

private Database open(string name)
{
	auto opts = new DBOptions;
	opts.createIfMissing = true;
	opts.errorIfExists = false;
	opts.compression = CompressionType.ZSTD;

	return new Database(opts, name);
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
