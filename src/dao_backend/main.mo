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

actor {

  // Storage of the data during upgrades
  stable var stableProposals : [Proposal.StableProposal] = [];

  // Storage of the data
  var proposals = Buffer.fromIter<Proposal.Proposal>(Iter.map(stableProposals.vals(), Proposal.fromStable));

  // Type alias for expressive index of inside the above Lists
  type ProposalIndex = Nat;
  type VoteIndex = Nat;

  public shared ({ caller }) func submitProposal(text : Text) : async ProposalIndex {
    // TODO: check if caller has permission to create proposal
    proposals.add(Proposal.create(caller, Utils.minutesToNs(100), text));
    return proposals.size() - 1;
  };

  public query func getProposal(index : ProposalIndex) : async Proposal.StableProposal {
    let proposal = proposals.get(index);
    return Proposal.toStable(proposal);
  };

  public query func getProposals(from : Nat, limit : Nat) : async [(Nat, Proposal.StableProposal)] {
    nyi(); // TODO: implement
  };

  public func vote(id : Nat, vote : Bool) {
    nyi(); // TODO: implement
  };

  public func modifyParameters() : async Result.Result<(), ()> {
    nyi(); // TODO: implement
  };

  //quadratic_voting createNeuron dissolveNeuron

  // Handle upgrades

  system func preupgrade() {
    stableProposals := Iter.toArray(Iter.map(proposals.vals(), Proposal.toStable));
  };

  system func postupgrade() {
    stableProposals := [];
  };
};
