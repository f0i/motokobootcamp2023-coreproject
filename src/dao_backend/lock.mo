import Principal "mo:base/Principal";
import Time "mo:base/Time";
import HashMap "mo:base/HashMap";

module Lock {
    type Principal = Principal.Principal;
    type HashMap<K, V> = HashMap.HashMap<K, V>;
    type Time = Time.Time;

    public let timeout : Int = 30_000_000_000; // break lock after 30 seconds

    /// Returns true if the lock is not set or expired
    func check_lock(locks : HashMap<Principal, Time>, caller : Principal) : Bool {
        switch (locks.get(caller)) {
            case (?lock) {
                return lock < Time.now();
            };
            case (null) {
                return true;
            };
        };
    };

    /// Try to set a lock. Returns false if lock is already set
    public func lock(locks : HashMap<Principal, Time>, caller : Principal) : Bool {
        if (check_lock(locks, caller)) {
            locks.put(caller, Time.now() + timeout);
            return true;
        } else {
            return false;
        };
    };

    /// Release a lock
    public func release(locks : HashMap<Principal, Time>, caller : Principal) : () {
        locks.delete(caller);
    };
};
