module types.packproxies;

// messagepack proxies

import msgpack : Packer, Unpacker;

static struct PPStdTime
{
	import std.datetime : SysTime, UTC;

	static void serialize(ref Packer p, ref in SysTime st)
	{
		p.pack(st.toUTC.stdTime);
	}

	static void deserialize(ref Unpacker u, ref SysTime st)
	{
		long stdTime = void;
		u.unpack(stdTime);
		st = SysTime(stdTime, UTC());
	}
}
