import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Float "mo:base/Float";

module {
    public type Time = Time.Time;

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

    /// Check if a neuron is dissolving
    public func isDissolving(neuron : Neuron) : Bool {
        switch (neuron.status) {
            case (#locked_for(_)) { return false };
            case (#locked_until(_)) { return true };
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

    // Calculate voting poser
    public func votingPower(neuron : Neuron) : Float {
        // check if age is over 6 months
        let sixMonths : Float = 6 * 30 * 24 * 60 * 60 * 1_000_000_000;
        let eightYears : Float = 8 * 356 * 24 * 60 * 60 * 1_000_000_000;
        let fourYears : Float = 4 * 356 * 24 * 60 * 60 * 1_000_000_000;
        let delay : Float = Float.fromInt(getDissolveDelay(neuron));
        if (delay < sixMonths) return 0;
        let delayBonus = 1 + Float.min(delay / eightYears, 1.0);

        let age : Float = Float.fromInt(getAge(neuron));
        let ageBonus : Float = 1 + Float.min(age / fourYears * 0.25, 0.25);
        let amount = Float.fromInt(neuron.amount);
        let amountPower : Float = amount / 100_000_000;

        return amountPower * delayBonus * ageBonus;
    };
};
