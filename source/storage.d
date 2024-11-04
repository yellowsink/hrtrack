// encrypted data storage utilities

import rocksdb : Database, WriteBatch;

import types : RawAESKey;

private:

Database open(string name)
{
	import rocksdb : DBOptions, CompressionType;

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

void put(DB, T, bool ENC = true)(DB db, const string key, const T value, const RawAESKey userDataKey)
{
	import cerealed : cerealise;
	import std.string : representation;

	auto cerealised = cerealise(value);

	static if (ENC)
		auto toPut = encrypt(userDataKey, cerealised);
	else
		auto toPut = cerealised;

	// rocks is fast enough to do this sync
	// cast away the immutable from the key because put() should take it const, the binding is even for `const char*`!!!
	db.put(cast(ubyte[]) key.representation, toPut);
}

T get(DB, T, bool ENC = true)(DB db, const string key, const RawAESKey userDataKey)
{
	import cerealed : decerealise;
	import std.string : representation;

	auto gotten = db.get(key.representation);

	static if (ENC)
		auto cerealised = decrypt!T(userDataKey, gotten);
	else
		auto cerealised = gotten;

	return decerealise!T(cerealised);
}

public:

struct DB
{
	import std.typecons : Nullable;

	private Database _db;
	private Nullable!WriteBatch _wb;

	this(string name)
	{
		_db = open(name);
	}

	~this()
	{
		if (!_wb.isNull) endBatch();

		_db.close();
	}

	void startBatch()
	{
		import std.exception : enforce;
		enforce(_wb.isNull, "cannot start a batch when you already have one open");
		_wb = new WriteBatch;
	}

	void endBatch()
	{
		import std.exception : enforce;
		enforce(!_wb.isNull, "cannot end a batch when you don't have one open");

		_db.write(_wb.get);
		_wb.nullify();
	}

	void put(T)(const string key, const T value, const RawAESKey userDataKey)
	{
		if (_wb.isNull)
			.put!(Database, T, true)(_db, key, value, userDataKey);
		else
			.put!(WriteBatch, T, true)(_wb.get, key, value, userDataKey);
	}

	void put(T)(const string key, const T value)
	{
		ubyte[32] udk = void;
		if (_wb.isNull)
			.put!(Database, T, false)(_db, key, value, udk);
		else
			.put!(WriteBatch, T, false)(_wb.get, key, value, udk);
	}

	T get(T)(const string key, const RawAESKey userDataKey)
	{
		return .get!(Database, T, true)(_db, key, userDataKey);
	}

	T get(T)(const string key)
	{
		ubyte[32] udk = void;
		return .get!(Database, T, false)(_db, key, udk);
	}

	void remove(const string key)
	{
		import std.string : representation;

		if (_wb.isNull)
			_db.remove(cast(ubyte[]) key.representation);
		else
			_wb.get.remove(cast(ubyte[]) key.representation);
	}
}
