import vibe.http.session;
import vibe.core.core : Timer, createLeanTimer, exitEventLoop;
import std.variant : Variant;
import core.time : MonoTime, Duration, dur;

// allow a user to stay logged in until her next shot :)
enum SESSION_TIMEOUT = dur!"weeks"(2);

// how often to clean up expired sessions
enum CLEANUP_INTERVAL = dur!"minutes"(1);

final class ExpiringMemorySessionStore : SessionStore
{
@safe:
	private Variant[string][string] _sessions;
	private MonoTime[string][string] _timeouts;

	//private Duration _timeoutLength;
	private alias _timeoutLength = SESSION_TIMEOUT;

	private Timer _cleanupTimer;

	this()
	{
		// lean timers need not create a task for each run but must not block the event loop
		_cleanupTimer = createLeanTimer(&cleanupExpiredKeys);
		_cleanupTimer.rearm(CLEANUP_INTERVAL, true);
	}

	~this()
	{
		_cleanupTimer.stop();
	}

	private void cleanupExpiredKeys() nothrow
	{
		import vibe.core.log;
		try {
			auto cleanupTime = MonoTime.currTime;

			foreach (kv; _sessions.byKeyValue)
			{
				if (kv.value is null) continue;

				foreach (key; kv.value.byKey)
				{
					if (_timeouts[kv.key][key] > cleanupTime)
						remove(kv.key, key);
				}
			}
		}
		catch (Exception e)
		{
			(() @trusted {
				logError("exception caught while cleaning up expired session keys: %s", e);
			})();
		}
	}

	private bool removeOrRefresh(string id, string name)
	{
		if (_timeouts[id][name] > MonoTime.currTime)
		{
			remove(id, name);
			return false;
		}
		else
		{
			_timeouts[id][name] = MonoTime.currTime + _timeoutLength;
			return true;
		}
	}

	const @property SessionStorageType storageType() { return SessionStorageType.native; }

	Session create()
	{
		auto s = createSessionInstance();
		_sessions[s.id] = null;
		_timeouts[s.id] = null;
		return s;
	}

	Session open(string id)
	{
		return id in _sessions ? createSessionInstance(id) : Session.init;
	}

	@trusted void set(string id, string name, Variant value)
	{
		_sessions[id][name] = value;
		_timeouts[id][name] = MonoTime.currTime + _timeoutLength;
	}

	@trusted Variant get(string id, string name, lazy Variant defaultValue)
	{
		assert(id in _sessions);
		assert(id in _timeouts);

		if (auto pv = name in _sessions[id])
		{
			if (removeOrRefresh(id, name)) return *pv;
		}

		return defaultValue;
	}

	bool isKeySet(string id, string name)
	{
		if (name in _sessions[id])
		{
			// handle timeout
			return removeOrRefresh(id, name);
		}
		return false;
	}

	void remove(string id, string name)
	{
		_sessions[id].remove(name);
		_timeouts[id].remove(name);
	}

	void destroy(string id)
	{
		_sessions.remove(id);
		_timeouts.remove(id);
	}

	@trusted int iterateSession(string id, scope int delegate(string key) @safe del)
	{
		assert(id in _sessions);
		foreach (key; _sessions[id].byKey)
		{
			if (removeOrRefresh(id, key))
				if (auto ret = del(key))
					return ret;
		}
		return 0;
	}
}
