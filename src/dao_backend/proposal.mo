import Time "mo:base/Time";
import Utils "utils";
import Principal "mo:base/Principal";
import Int "mo:base/Int";
import Bool "mo:base/Bool";

module Proposal {

    type Status = { #draft; #active; #accepted; #rejected };

    public type Proposal = {
        content : Text;
        creator : Principal;
        createdAt : Time.Time;
        durationNs : Nat;
        status : Status;
        votes : HashMap<Principal, Vote>;
    };

    public type StableProposal = {
        content : Text;
        creator : Principal;
        createdAt : Time.Time;
        durationNs : Nat;
        status : Status;
        votes : [Vote];
    };

    /// Returns a new proposal
    public func create(creator : Principal, durationInMinutes : Nat, content : Text) : Proposal {
        return {
            content;
            creator;
            createdAt = Time.now();
            durationNs = Int.abs(Utils.minutesToNs(durationInMinutes));
            status = #draft;
        };
    };

    public func isActive(proposal : Proposal) : Bool {
        return proposal.status == #active;
    };

    public func toStable(p : Proposal) : StableProposal {
        return {
            content = p.context;
            creator = p.creator;
            createdAt = p.createdAt;
            durationNs = p.durationNs;
            status = p.status;
            votes = Iter.toArray(p.votes.entries());
        };
    };

};
