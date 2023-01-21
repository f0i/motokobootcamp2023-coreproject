import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Principal "mo:base/Principal";
import Hash "mo:base/Hash";
import Int32 "mo:base/Int32";

/// Helper functions
module Utils {
    type Principal = Principal.Principal;

    public func createNatMap<T>() : HashMap.HashMap<Nat, T> {
        return HashMap.HashMap<Nat, T>(0, Nat.equal, Nat32.fromIntWrap);
    };

    public func minutesToNs(s : Int) : Int {
        return s /*minutes*/ * 60 /*seconds*/ * 1000 /*ms*/ * 1000 /*us*/ * 1000 /*ns*/;
    };

    public func prinipalNatTupleEqual((p1 : Principal, n1 : Nat), (p2 : Principal, n2 : Nat)) : Bool {
        return p1 == p2 and n1 == n2;
    };

    public func prinipalNatTupleHash((p : Principal, n : Nat)) : Hash.Hash {
        let hash1 = Principal.hash(p);
        let hash2 = Nat32.fromIntWrap(n);
        return hash1 ^ hash2;
    };

    public func min3(a : Nat, b : Nat, c : Nat) : Nat = Nat.min(Nat.min(a, b), c);
};
