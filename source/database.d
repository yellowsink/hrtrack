// functions to talk to rocksdb with encryption support

import rocksdb;

private Database open(string name)
{
	auto opts = new DBOptions;
	opts.createIfMissing = true;
	opts.errorIfExists = false;
	opts.compression = CompressionType.ZSTD;

	return new Database(opts, name);
}

