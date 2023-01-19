import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Utils "utils";
import Principal "mo:base/Principal";
import Proposal "proposal";
import Iter "mo:base/Iter";
import TrieMap "mo:base/TrieMap";
import List "mo:base/List";
import Vote "vote";
import Buffer "mo:base/Buffer";

actor {

  // Storage of the data during upgrades
  stable var stableVotes : [Vote.Vote] = [];
  stable var stableProposals : [Proposal.Proposal] = [];

  // Storage of the data
  var proposals = Buffer.fromArray<Proposal.Proposal>(stableProposals);
  var votes = Buffer.fromArray<Vote.Vote>(stableVotes);

  // Type alias for expressive index of inside the above Lists
  type ProposalIndex = Nat;
  type VoteIndex = Nat;
  type TrieMap = TrieMap.TrieMap;

  // lookup tables
  var votesByUser = TrieMap<Principal, VoteIndex>(Principal.equal, Principal.hash);
  var votesByUserAndProposal = TrieMap.TrieMap<(Principal, Nat), VoteIndex>(Utils.principalNatEqual, Utils.principalNatHash);
  var votesByProposal = TrieMap<ProposalIndex, List<VoteIndex>>(Nat.equal, Int32.fromIntWrap);

  // Update lookup tables
  for (i in Iter.range(0, votes.size() - 1)) {
    let vote = votes.get(i);
  };

  public query func get_proposal() : async Text {
    return ""; // TODO: implement
  };

  public query func get_all_proposals(from : Nat, limit : Nat) : async [(Nat, Proposal.Proposal)] {
    return []; // TODO: implement
  };

  public query func get_my_proposals(from : Nat, limit : Nat) : async [(Nat, Proposal.Proposal)] {
    return []; // TODO: implement
  };

  public func vote(id : Nat, vote : Bool) {
    // TODO: implement
  };

  // Handle upgrades

  system func preupgrade() {
    stableProposals := Buffer.toArray(proposals);
    stableVotes := Buffer.toArray(votes);
  };

  system func postupgrade() {
    stableProposals := [];
    stableVotes := [];
  };
};
