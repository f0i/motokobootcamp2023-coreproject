// @verify

import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Proposal "proposal";

module Vote {

    public type Decision = { #support; #decline };
    public type VotingError = { #notActive; #noCoins; #voterMismatch };

    // Less verbose type alias
    type Proposal = Proposal.Proposal;

    /// Information about one vote
    public type Vote = {
        voter : Principal;
        var decision : Decision;
    };

    /// Create a new proposal
    public func vote(proposal : Proposal.Proposal, voter : Principal, decision : Decision) : Result.Result<Vote, VotingError> {
        // Only vote on active proposals
        if (not Proposal.isActive(proposal)) {
            return #err(#notActive);
        };

        return #ok {
            voter;
            var decision;
        };
    };

    /// Update the decision on a previous vote
    /// Returns true if the update was permitted and successful
    public func update(proposal : Proposal.Proposal, vote : Vote, voter : Principal, decision : Decision) : Result.Result<(), VotingError> {
        // Only update your own proposals
        if (vote.voter != voter) {
            return #err(#voterMismatch);
        };

        // Only vote on active proposals
        if (not Proposal.isActive(proposal)) {
            return #err(#notActive);
        };

        // All checks above passed -> update the vote
        vote.decision := decision;
        return #ok;
    };
};
