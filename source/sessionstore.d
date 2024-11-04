import vibe.http.session;
import vibe.core.core : Timer, createLeanTimer, exitEventLoop;
import std.variant : Variant;
import core.time : MonoTime, Duration, dur;

// allow a user to stay logged in until her next shot :)
// i am fully aware that the standard recommendation is like 15 minutes. bleh.
enum SESSION_TIMEOUT = dur!"weeks"(2);

// how often to clean up expired sessions
enum CLEANUP_INTERVAL = dur!"minutes"(1);

final class ExpiringMemorySessionStore : SessionStore
{
@safe:
	private Variant[string][string] _sessions;
	private MonoTime[string] _timeouts;

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
			foreach (sess; _sessions.byKey)
				cleanupIfExpired(sess);
		}
		catch (Exception e)
		{
			(() @trusted {
				logError("exception caught while cleaning up expired session keys: %s", e);
			})();
		}
	}

	// returns true if expired
	private bool cleanupIfExpired(string id)
	{
		if (!(id in _timeouts) || (_timeouts[id] < MonoTime.currTime))
		{
			_sessions.remove(id);
			_timeouts.remove(id);
			return true;
		}
		return false;
	}

	// returns true if still alive
	private bool expireOrRefresh(string id)
	{
		assert(id in _sessions);

		if (!cleanupIfExpired(id))
		{
			_timeouts[id] = MonoTime.currTime + _timeoutLength;
			return true;
		}
		return false;
	}

	const @property SessionStorageType storageType() { return SessionStorageType.native; }

	Session create()
	{
		auto s = createSessionInstance();
		_sessions[s.id] = null;
		_timeouts[s.id] = MonoTime.currTime + _timeoutLength;
		return s;
	}

	Session open(string id)
	{
		return id in _sessions ? createSessionInstance(id) : Session.init;
	}

	@trusted void set(string id, string name, Variant value)
	{
		assert(expireOrRefresh(id));
		_sessions[id][name] = value;
	}

	@trusted Variant get(string id, string name, lazy Variant defaultValue)
	{
		assert(expireOrRefresh(id));

		if (auto pv = name in _sessions[id])
			return *pv;

		return defaultValue;
	}

	bool isKeySet(string id, string name)
	{
		return expireOrRefresh(id) && (name in _sessions[id]) !is null;
	}

	void remove(string id, string name)
	{
		assert(expireOrRefresh(id));
		_sessions[id].remove(name);
	}

	void destroy(string id)
	{
		_sessions.remove(id);
		_timeouts.remove(id);
	}

	@trusted int iterateSession(string id, scope int delegate(string key) @safe del)
	{
		assert(id in _sessions);
		assert(expireOrRefresh(id));

		foreach (key; _sessions[id].byKey)
			if (auto ret = del(key))
				return ret;

		return 0;
	}
}
