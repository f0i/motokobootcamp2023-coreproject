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

    type Status = { #draft; #active; #accepted; #rejected };
    type VotingError = { #notActive; #noCoins };

    type Vote = Vote.Vote;
    type TrieMap<K, V> = TrieMap.TrieMap<K, V>;

    public type Proposal = {
        content : Text;
        creator : Principal;
        createdAt : Time.Time;
        durationNs : Nat;
        status : Status;
        votes : TrieMap<Principal, Vote>;
    };

    public type StableProposal = {
        content : Text;
        creator : Principal;
        createdAt : Time.Time;
        durationNs : Nat;
        status : Status;
        votes : [(Principal, Vote)];
    };

    /// Returns a new proposal
    public func create(creator : Principal, durationInMinutes : Int, content : Text) : Proposal {
        return {
            content;
            creator;
            createdAt = Time.now();
            durationNs = Int.abs(Utils.minutesToNs(durationInMinutes));
            status = #draft;
            votes = TrieMap.TrieMap<Principal, Vote>(Principal.equal, Principal.hash);
        };
    };

    public func isActive(proposal : Proposal) : Bool {
        return proposal.status == #active;
    };

    public func toStable(p : Proposal) : StableProposal {
        return {
            content = p.content;
            creator = p.creator;
            createdAt = p.createdAt;
            durationNs = p.durationNs;
            status = p.status;
            votes = Iter.toArray<(Principal, Vote)>(p.votes.entries());
        };
    };

    public func fromStable(p : StableProposal) : Proposal {
        return {
            content = p.content;
            creator = p.creator;
            createdAt = p.createdAt;
            durationNs = p.durationNs;
            status = p.status;
            votes = TrieMap.fromEntries<Principal, Vote>(p.votes.vals(), Principal.equal, Principal.hash);
        };
    };

    /// Add a vote for the user to a proposal, if proposal is active
    public func vote(proposal : Proposal.Proposal, voter : Principal, decision : Vote.Decision) : Result.Result<(), VotingError> {
        // Only vote on active proposals
        if (not Proposal.isActive(proposal)) {
            return #err(#notActive);
        };

        let vote = Vote.init(decision);

        proposal.votes.put(voter, vote);

        return #ok;
    };

};
