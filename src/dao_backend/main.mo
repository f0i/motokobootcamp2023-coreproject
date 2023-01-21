import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Utils "utils";
import Principal "mo:base/Principal";
import Proposal "proposal";
import Iter "mo:base/Iter";
import List "mo:base/List";
import Vote "vote";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import { nyi } "mo:base/Prelude";
import Result "mo:base/Result";
import { compose } "mo:base/Func";
import Int "mo:base/Int";
import Error "mo:base/Error";
import MbToken "mb_token";

actor {

  // Storage of the data during upgrades
  stable var stableProposals : [Proposal.StableProposal] = [];
  let maxProposalsPerRequest = 50;
  let mbToken = MbToken.getCanister();

  // Storage of the data
  var proposals = Buffer.fromIter<Proposal.Proposal>(Iter.map(stableProposals.vals(), Proposal.fromStable));

  // Type alias for expressive index of inside the above Lists
  type ProposalIndex = Nat;
  type VoteIndex = Nat;

  /// update function to add a new proposal
  public shared ({ caller }) func submitProposal(text : Text) : async ProposalIndex {
    // TODO: check if caller has permission to create proposals

    proposals.add(Proposal.create(caller, 100, text));
    return proposals.size() - 1;
  };

  /// Return a single proposal
  public query func getProposal(index : ProposalIndex) : async Proposal.StableProposal {
    // check index
    if (index >= proposals.size()) throw Error.reject("Proposal ID does not exist");

    let proposal = proposals.get(index);
    return Proposal.toStable(proposal);
  };

  /// Get a list of proposals
  public query func getProposals(from : Int, limit : Nat) : async [(Nat, Proposal.StableProposal)] {
    // check range
    var start = if (from >= 0) {
      Int.abs(from); // "cast" positive `Int` to `Nat`
    } else {
      // convert negative numbers to index counted from the end of the buffer
      // example 1: for Buffer[p0, p1, p2, p3, p4, p5] and parameter `from = -2` will start at index `4`
      // example 2: pass in `from = -1` to get only the last element
      Int.abs(Int.max(proposals.size() + from, 0));
    };
    if (from >= proposals.size()) return [];

    let until = Utils.min3(start + limit, start + maxProposalsPerRequest, proposals.size() - 1);
    let range = Iter.range(start, until);

    // collect proposals
    let props = Iter.map<Nat, (Nat, Proposal.StableProposal)>(
      range,
      func(i : Nat) : (Nat, Proposal.StableProposal) {
        return (i, Proposal.toStable(proposals.get(i)));
      },
    );
    return Iter.toArray(props);
  };

  /// Submit your vote
  public shared ({ caller }) func vote(proposal_id : ProposalIndex, vote : Vote.Decision) : async Result.Result<(), Proposal.VotingError> {
    let proposal = proposals.get(proposal_id);

    // TODO: check MB balance
    let votingPower : Float = 1;

    return Proposal.vote(proposal, caller, votingPower, vote);
  };

  type Parameter = { #maxPowerFactor : Float };
  public func modifyParameters(parameter : Parameter) : async Result.Result<(), ()> {
    nyi(); // TODO: implement
  };

  public func quadraticVoting(activate : Bool) : async () {
    nyi(); // TODO: implement
  };

  public func createNeuron() {
    nyi(); // TODO: implement
  };
  public func dissolveNeuron() {
    nyi(); // TODO: implement
  };

  public shared ({ caller }) func callerBalance() : async Nat {
    let balance = await mbToken.icrc1_balance_of(caller);
    return balance;
  };

  // Handle upgrades

  system func preupgrade() {
    stableProposals := Iter.toArray(Iter.map(proposals.vals(), Proposal.toStable));
  };

  system func postupgrade() {
    stableProposals := [];
  };
};
