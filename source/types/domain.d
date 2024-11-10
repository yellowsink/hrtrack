module types.domain;

// database types

import std.datetime : SysTime;

import types.packproxies;
import msgpack : serializedAs;

alias RawAESKey = ubyte[256 / 8];

alias Hash = ubyte[256 / 8];

struct UserDataAccessKey
{
	Hash hash;
	@serializedAs!PPStdTime SysTime createdAt;
}

struct UserData
{
	ulong id;
	@serializedAs!PPStdTime SysTime createdAt;
	@serializedAs!PPStdTime SysTime modifiedAt;
	UserDataAccessKey[] accessKeys;
}

