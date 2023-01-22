import Time "mo:base/Time";
import Utils "utils";
import Principal "mo:base/Principal";
import Int "mo:base/Int";
import Bool "mo:base/Bool";
import TrieMap "mo:base/TrieMap";
import Vote "vote";
import Result "mo:base/Result";
import Iter "mo:base/Iter";

module Proposal {

    type Status = { #active; #accepted; #rejected };
    public type VotingError = { #notActive; #notEnoughVotingPower };
    public type ProposeError = { #notEnoughVotingPower };

    type Vote = Vote.Vote;
    type TrieMap<K, V> = TrieMap.TrieMap<K, V>;

    public type Proposal = {
        content : Text;
        creator : Principal;
        createdAt : Time.Time;
        durationNs : Nat;
        var status : Status;
        var votes : TrieMap<Principal, Vote>;
        var supported : Float;
        var rejected : Float;
    };

    public type StableProposal = {
        content : Text;
        creator : Principal;
        createdAt : Time.Time;
        durationNs : Nat;
        status : Status;
        votes : [(Principal, Vote)];
        supported : Float;
        rejected : Float;
    };

    /// Returns a new proposal
    public func create(creator : Principal, durationInMinutes : Int, content : Text) : Proposal {
        return {
            content;
            creator;
            createdAt = Time.now();
            durationNs = Int.abs(Utils.minutesToNs(durationInMinutes));
            var status = #active;
            var votes = TrieMap.TrieMap<Principal, Vote>(Principal.equal, Principal.hash);
            var supported = 0;
            var rejected = 0;
        };
    };

    /// Add a vote for the user to a proposal, if proposal is active
    /// Returns a result with the total voting power in this proposal or a voting error
    public func vote(proposal : Proposal.Proposal, voter : Principal, votingPower : Float, decision : Vote.Decision) : Result.Result<Status, VotingError> {
        if (votingPower < 1) {
            return #err(#notEnoughVotingPower);
        };

        // Only vote on active proposals
        if (not Proposal.isActive(proposal)) {
            return #err(#notActive);
        };

        // Remove old vote from count
        switch (proposal.votes.get(voter)) {
            case (?({ date = _; decision = #support; power })) {
                proposal.supported -= power;
            };
            case (?({ date = _; decision = #reject; power })) {
                proposal.rejected -= power;
            };
            case (null) {
                // voter did not vote yet
            };

        };
        // add vote to count
        switch (decision) {
            case (#support) { proposal.supported += votingPower };
            case (#reject) { proposal.rejected += votingPower };
        };

        // store vote
        let vote = Vote.init(decision, votingPower);
        proposal.votes.put(voter, vote);

        // check result
        if (proposal.supported > 100 or proposal.rejected > 100) {
            if (proposal.supported > proposal.rejected) {
                proposal.status := #accepted;
            } else {
                proposal.status := #rejected;
            };
        };

        return #ok(proposal.status);
    };

    /// Check if a proposal is currently active
    public func isActive(proposal : Proposal) : Bool {
        return proposal.status == #active;
    };

    // Helper to write data to stable memory before updates

    /// Return a data structure that can be stored in stable memory
    public func toStable(p : Proposal) : StableProposal {
        return {
            content = p.content;
            creator = p.creator;
            createdAt = p.createdAt;
            durationNs = p.durationNs;
            status = p.status;
            votes = Iter.toArray<(Principal, Vote)>(p.votes.entries());
            supported = p.supported;
            rejected = p.rejected;
        };
    };

    /// Restore a proposal from stable memory
    public func fromStable(p : StableProposal) : Proposal {
        return {
            content = p.content;
            creator = p.creator;
            createdAt = p.createdAt;
            durationNs = p.durationNs;
            var status = p.status;
            var votes = TrieMap.fromEntries<Principal, Vote>(p.votes.vals(), Principal.equal, Principal.hash);
            var supported = p.supported;
            var rejected = p.rejected;
        };
    };

};
