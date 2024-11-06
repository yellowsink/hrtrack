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

void put(DB, T, bool ENC = true)(DB db, const ubyte[] key, const T value, const RawAESKey aesKey)
{
	import crypt : encrypt;
	import cerealed : cerealise;

	auto cerealised = cerealise(value);

	static if (ENC)
		auto toPut = encrypt(aesKey, cerealised);
	else
		auto toPut = cerealised;

	// rocks is fast enough to do this sync
	// cast away the immutable from the key because put() should take it const, the binding is even for `const char*`!!!
	db.put(cast(ubyte[]) key, toPut);
}

T get(DB, T, bool ENC = true)(DB db, const ubyte[] key, const RawAESKey aesKey)
{
	import crypt : decrypt;
	import cerealed : decerealise;
	import std.string : assumeUTF;

	auto gotten = db.get(cast(ubyte[]) key);

	if (gotten.length == 0) throw new KeyNotPresentException(("Key '" ~ key.assumeUTF ~ "' not present").dup);

	static if (ENC)
		auto cerealised = decrypt(aesKey, gotten);
	else
		auto cerealised = gotten;

	return decerealise!T(cerealised);
}

public:

class KeyNotPresentException : Exception
{
	this(string msg)
	{
		super(msg);
	}
}

// each db key is of the form [KeyType, ...]
// numeric IDs are stored in big-endian, because it is the correct endian.
enum KeyType : ubyte
{
	// uid -> UserData
	UserDataById,
	// uid ~ akey[0..4] -> udkey
	UDKeyByAccessKey,
}

struct DB
{
	import std.typecons : Nullable;
	import std.bitmanip : bigEndianToNative, nativeToBigEndian;
	import std.exception : enforce;

	import types;

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

	// basic operations

	void startBatch()
	{
		enforce(_wb.isNull, "cannot start a batch when you already have one open");
		_wb = new WriteBatch;
	}

	void endBatch()
	{
		enforce(!_wb.isNull, "cannot end a batch when you don't have one open");

		_db.write(_wb.get);
		_wb.nullify();
	}

	void abandonBatch()
	{
		enforce(!_wb.isNull, "cannot abandon a batch when you don't have one open");
		_wb.nullify();
	}

	void atomic(void delegate() fn)
	{
		auto shouldBatch = _wb.isNull;
		if (shouldBatch) startBatch();

		scope(failure)
			if (shouldBatch) abandonBatch();

		scope(success)
			if (shouldBatch) endBatch();

		fn();
	}

	void put(T)(const ubyte[] key, const T value, const RawAESKey aesKey)
	{
		if (_wb.isNull)
			.put!(Database, T, true)(_db, key, value, aesKey);
		else
			.put!(WriteBatch, T, true)(_wb.get, key, value, aesKey);
	}

	void put(T)(const ubyte[] key, const T value)
	{
		ubyte[32] udk = void;
		if (_wb.isNull)
			.put!(Database, T, false)(_db, key, value, udk);
		else
			.put!(WriteBatch, T, false)(_wb.get, key, value, udk);
	}

	Nullable!T get(T)(const ubyte[] key, const RawAESKey aesKey)
	{
		try
		{
			return Nullable!T(.get!(Database, T, true)(_db, key, aesKey));
		}
		catch (KeyNotPresentException)
		{
			return Nullable!T.init;
		}
	}

	Nullable!T get(T)(const ubyte[] key)
	{
		ubyte[32] udk = void;
		try
		{
			return Nullable!T(.get!(Database, T, false)(_db, key, udk));
		}
		catch (KeyNotPresentException)
		{
			return Nullable!T.init;
		}
	}

	bool includes(const ubyte[] key)
	{
		return _db.get(cast(ubyte[]) key).length != 0;
	}

	void remove(const ubyte[] key)
	{
		if (_wb.isNull)
			_db.remove(cast(ubyte[]) key);
		else
			_wb.get.remove(cast(ubyte[]) key);
	}

	// domain operations

	private ubyte[] accessKeyDbKey(ulong uid, RawAESKey ak)
	{
		return KeyType.UDKeyByAccessKey ~ uid.nativeToBigEndian ~ ak[0..4];
	}

	void addAccessKey(const ulong uid, const RawAESKey accessKey, const RawAESKey userDataKey)
	{
		const key = accessKeyDbKey(uid, accessKey);
		enforce(!includes(key));
		put(key, userDataKey, accessKey);
	}

	Nullable!RawAESKey getUserDataKey(const ulong id, const RawAESKey accessKey)
	{
		return get!RawAESKey(accessKeyDbKey(id, accessKey), accessKey);
	}

	bool hasUser(const ulong id)
	{
		return includes(KeyType.UserDataById ~ id.nativeToBigEndian);
	}

	Nullable!UserData getUserById(const ulong id, const RawAESKey encKey)
	{
		return get!UserData(KeyType.UserDataById ~ id.nativeToBigEndian, encKey);
	}

	AuthedUserSession createUser(const ulong id, const RawAESKey accessKey)
	{
		import crypt : rand;

		const userDataKey = rand!RawAESKey();

		auto user = UserData(id);

		// TODO: we need some kind of way of checking that the decryption key is actually correct.
		atomic({
			put(KeyType.UserDataById ~ id.nativeToBigEndian, user, userDataKey);
			addAccessKey(id, accessKey, userDataKey);
		});

		return AuthedUserSession(id, userDataKey);
	}
}

DB database()
{
	return DB("HRTRACK_DB");
}
