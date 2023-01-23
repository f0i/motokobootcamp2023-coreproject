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
import Float "mo:base/Float";
import Array "mo:base/Array";
import Webpage "webpage";
import Parameter "parameter";
import Neuron "neuron";
import Lock "lock";
import Time "mo:base/Time";

actor Self {
  // Type alias for expressive index of inside the above Lists
  type ProposalIndex = Nat;
  type VoteIndex = Nat;
  type Result<OK, ERR> = Result.Result<OK, ERR>;
  type StableProposal = Proposal.StableProposal;
  type Parameter = Parameter.Parameter;
  public type Neuron = Neuron.Neuron;
  type Time = Time.Time;

  // Storage of the data during upgrades
  stable var stableProposals : [Proposal.StableProposal] = [];
  stable var stableNeurons : [(Principal, Neuron)] = [];
  let maxProposalsPerRequest = 100;
  let mbToken = MbToken.getCanister();
  let dao_webpage = Webpage.getCanister();

  // Storage of the data
  var proposals = Buffer.fromIter<Proposal.Proposal>(Iter.map(stableProposals.vals(), Proposal.fromStable));
  var neurons = HashMap.fromIter<Principal, Neuron>(stableNeurons.vals(), stableNeurons.size(), Principal.equal, Principal.hash);

  // Locks
  var locks = HashMap.HashMap<Principal, Time>(0, Principal.equal, Principal.hash);

  /// update function to add a new proposal
  public shared ({ caller }) func submitProposal(text : Text) : async Result<ProposalIndex, Proposal.ProposeError> {
    let balance = await mbToken.icrc1_balance_of(MbToken.getAccount(caller, null));

    if (balance < 1) return #err(#notEnoughVotingPower);

    proposals.add(Proposal.create(caller, 100, text));
    return #ok(proposals.size() - 1);
  };

  /// Return a single proposal
  public query func getProposal(index : ProposalIndex) : async StableProposal {
    // check index
    if (index >= proposals.size()) throw Error.reject("Proposal ID does not exist");

    let proposal = proposals.get(index);
    return Proposal.toStable(proposal);
  };

  /// Get a list of proposals
  public query func getProposals(from : Int, limit : Nat) : async [(Nat, StableProposal)] {
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
    return Array.reverse(Iter.toArray(props));
  };

  /// Submit your vote
  public shared ({ caller }) func vote(proposal_id : ProposalIndex, vote : Vote.Decision) : async Result.Result<(), Proposal.VotingError> {

    // check in user controlled account
    //let balance = await mbToken.icrc1_balance_of(MbToken.getAccount(caller, null));
    //let votingPower : Float = Float.fromInt(balance) / Float.pow(10, 8);

    // check in dao controlled account
    let votingPower = switch (neurons.get(caller)) {
      case (?neuron) { Neuron.votingPower(neuron) };
      case (null) { 0.0 };
    };

    let proposal = proposals.get(proposal_id);
    let result = Proposal.vote(proposal, caller, votingPower, vote);
    switch (result) {
      case (#err(e)) { return #err(e) };
      case (#ok(#accepted)) {
        await dao_webpage.updateText(proposal.content);
        return #ok;
      };
      case (#ok(_)) { return #ok };
    };
  };

  public func modifyParameters(parameter : Parameter) : async Result.Result<(), ()> {
    nyi(); // TODO: implement
  };

  public func quadraticVoting(activate : Bool) : async () {
    nyi(); // TODO: implement
  };

  /// Check user balance and create a neuron
  /// Frontend should use getTransferArgs() and initiate a transfer with the connected wallet before calling this function
  public shared ({ caller }) func createNeuron(amount : Nat, delay : Nat) : async Result<(), MbToken.TransferError> {
    if (amount < 10 ** 8) throw Error.reject("Amount too low");

    // check if caller already has a neuron
    switch (neurons.get(caller)) {
      case (?neuron) {
        throw Error.reject("Neuron already exists. Maybe use 'Add more tokens' instead?");
      };
      case (null) {};
    };

    // TODO: looks like this lock is not needed anymore
    if (not Lock.lock(locks, caller)) {
      throw Error.reject("Transaction in progress");
    };

    // check balance in subaccount of caller
    let self = Principal.fromActor(Self);
    let balance = await mbToken.icrc1_balance_of(MbToken.getAccount(self, ?caller));
    if (balance < 10 ** 8) throw Error.reject("Amount too low");

    Lock.release(locks, caller);

    // create neuron for user
    let neuron = Neuron.create(balance, delay);
    neurons.put(caller, neuron);

    return #ok;
  };

  /// Initiate a MBT transfer and top up neuron
  public shared ({ caller }) func topUpNeuron() : async Result<(), MbToken.TransferError> {

    // check if caller already has a neuron
    let neuron = switch (neurons.get(caller)) {
      case (?neuron) {
        neuron;
      };
      case (null) {
        throw Error.reject("You don't have a neuron :(");
      };
    };

    if (not Lock.lock(locks, caller)) {
      throw Error.reject("Transaction in progress");
    };

    let self = Principal.fromActor(Self);
    let balance = await mbToken.icrc1_balance_of(MbToken.getAccount(self, ?caller));
    if (balance < 10 ** 8) throw Error.reject("Amount too low");

    Lock.release(locks, caller);

    // update neuron amount
    neuron.amount := balance;

    return #ok;
  };

  /// Get neuron information
  public shared ({ caller }) func getNeuron() : async ?{
    amount : Nat;
    dissolving : Bool;
    age : Nat;
    delay : Nat;
  } {
    switch (neurons.get(caller)) {
      case (?neuron) {
        return ?{
          amount = neuron.amount;
          dissolving = Neuron.isDissolving(neuron);
          age = Neuron.getAge(neuron);
          delay = Neuron.getDissolveDelay(neuron);
        };
      };
      case (null) {
        null;
      };
    };
  };

  /// Lock neuron and increase dissolve delay
  public shared ({ caller }) func lockNeuron(lockFor : Nat) : async () {
    switch (neurons.get(caller)) {
      case (?neuron) {
        Neuron.lock(neuron, lockFor);
      };
      case (null) {
        throw Error.reject("You don't have a neuron :(");
      };
    };
  };

  /// Start dissolving a neuron
  public shared ({ caller }) func dissolveNeuron() : async () {
    switch (neurons.get(caller)) {
      case (?neuron) {
        Neuron.dissolve(neuron);
      };
      case (null) {
        throw Error.reject("You don't have a neuron :(");
      };
    };
  };

  /// Start dissolving a neuron
  public shared ({ caller }) func disburseNeuron() : async Result<(), MbToken.TransferError> {
    // check if neuron exists and is dissolved
    let neuron = switch (neurons.get(caller)) {
      case (?neuron) {
        if (not Neuron.isDissolved(neuron)) throw Error.reject("Neuron is not dissolved");
        neuron;
      };
      case (null) {
        throw Error.reject("You don't have a neuron :(");
      };
    };

    if (not Lock.lock(locks, caller)) {
      throw Error.reject("Transaction in progress");
    };

    // Initiate transfer
    let status = await mbToken.icrc1_transfer(
      MbToken.createTxTransferArgs(
        Principal.fromActor(Self),
        caller,
        neuron.amount,
      ),
    );

    Lock.release(locks, caller);

    // Check result
    switch (status) {
      case (#err(error)) { return #err(error) };
      case (#ok(_id)) {};
    };

    neurons.delete(caller);

    return #ok;
  };

  /// Get account for deposits
  public shared ({ caller }) func getTransferArgs(amount : Nat) : async MbToken.TransferArgs {
    if (amount < 10_000_000) throw Error.reject("Amount too low");
    return MbToken.createRxTransferArgs(
      caller,
      Principal.fromActor(Self),
      amount,
    );
  };

  /// Get the voting power
  public shared ({ caller }) func votingPower() : async Float {
    switch (neurons.get(caller)) {
      case (?neuron) { return Neuron.votingPower(neuron) };
      case (null) { return 0.0 };
    };
  };

  /// Get the current balance of MBT
  /// Frontend could also request this directly from the token ledger
  public shared ({ caller }) func callerBalance() : async Nat {
    let balance = await mbToken.icrc1_balance_of(MbToken.getAccount(caller, null));
    return balance;
  };

  // Handle upgrades

  /// Store proposals and neurons in stable memory during upgrades
  system func preupgrade() {
    stableProposals := Iter.toArray(Iter.map(proposals.vals(), Proposal.toStable));
    stableNeurons := Iter.toArray(neurons.entries());
  };

  // Reset stable variables after upgrade
  system func postupgrade() {
    stableProposals := [];
    stableNeurons := [];
  };
};
