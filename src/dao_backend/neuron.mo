import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Int "mo:base/Int";

module {
    type Time = Time.Time;

    let maxDissolveDelay : Nat = 126144000000000000; // 4 years: 4 * 365 * 24 * 60 * 60 * 1000000000;

    public type Status = { #locked_for : Nat; #locked_until : Time };

    public type Neuron = {
        var amount : Nat;
        var status : Status;
        var lockedSince : Time;
    };

    /// Get a new neuron
    public func create(amount : Nat, lockFor : Nat) : Neuron {
        let duration = Nat.min(lockFor, maxDissolveDelay);
        return {
            var amount = amount;
            var status = #locked_for(lockFor);
            var lockedSince = Time.now();
        };
    };

    /// Start dissolving
    public func dissolve(neuron : Neuron) : () {
        switch (neuron.status) {
            case (#locked_for(duration)) {
                let time = Time.now() + duration;
                neuron.status := #locked_until(time);
            };
            case (#locked_until(_time)) {
                // already dissolving
            };
        };
    };

    /// Get time since the neuron was locked
    public func getAge(neuron : Neuron) : Nat {
        switch (neuron.status) {
            case (#locked_for(duration)) {
                return Int.abs(Time.now() - neuron.lockedSince);
            };
            case (#locked_until(_time)) {
                return 0;
            };
        };
    };

    /// Get remaining locked time
    public func getDissolveDelay(neuron : Neuron) : Nat {
        switch (neuron.status) {
            case (#locked_for(duration)) {
                return duration;
            };
            case (#locked_until(time)) {
                let now = Time.now();
                if (now < time) {
                    return Int.abs(time - now);
                } else {
                    return 0;
                };
            };
        };
    };

    /// Check if a neuron is dissolved
    public func isDissolved(neuron : Neuron) : Bool {
        getDissolveDelay(neuron) == 0;
    };

    /// Lock and increase dissolve delay
    public func lock(neuron : Neuron, lockFor : Nat) {
        let duration = switch (neuron.status) {
            case (#locked_for(duration)) { duration };
            case (#locked_until(_time)) { getDissolveDelay(neuron) };
        };

        let newDuration = Nat.min(Nat.max(duration, lockFor), maxDissolveDelay);
        neuron.status := #locked_for(newDuration);
    };

    /// increase the staked amount in neuron
    public func increaseAmount(neuron : Neuron, amount : Nat) {
        // deduct age bonus
        neuron.lockedSince := Time.now();

        // update the amount
        let newAmount = neuron.amount + amount;
        neuron.amount := newAmount;
    };
};
