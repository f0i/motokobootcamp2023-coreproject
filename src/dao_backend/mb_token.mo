import Principal "mo:base/Principal";
import Blob "mo:base/Blob";
import Prelude "mo:base/Prelude";
import Sha224 "mo:sha224/SHA224";
import Nat8 "mo:base/Nat8";
import CRC32 "./checksum/crc32";
import Nat32 "mo:base/Nat32";
import Array "mo:base/Array";
import Time "mo:base/Time";
import Text "mo:base/Text";
import Nat64 "mo:base/Nat64";

module MbToken {
    type Subaccount = Blob.Blob;
    type Account = { owner : Principal; subaccount : ?Subaccount };

    /// Arguments for a transfer operation
    public type TransferArgs = {
        from_subaccount : ?Subaccount;
        to : Account;
        amount : Balance;
        fee : ?Balance;
        memo : ?Blob;

        /// The time at which the transaction was created.
        /// If this is set, the canister will check for duplicate transactions and reject them.
        created_at_time : ?Nat64;
    };

    public type TimeError = {
        #TooOld;
        #CreatedInFuture : { ledger_time : Timestamp };
    };

    public type TransferError = TimeError or {
        #BadFee : { expected_fee : Balance };
        #BadBurn : { min_burn_amount : Balance };
        #InsufficientFunds : { balance : Balance };
        #Duplicate : { duplicate_of : TxIndex };
        #TemporarilyUnavailable;
        #GenericError : { error_code : Nat; message : Text };
    };

    public type TransferResult = {
        #Ok : TxIndex;
        #Err : TransferError;
    };

    public type Balance = Nat;
    public type TxIndex = Nat;
    public type Timestamp = Nat64;

    /// Get actor instance to communicate with canister
    public func getCanister() : actor {
        icrc1_balance_of : (Account) -> async Nat;
        icrc1_name : () -> async Text;
        icrc1_symbol : () -> async Text;
        icrc1_transfer : TransferArgs -> async TransferResult;
    } {
        return actor ("db3eq-6iaaa-aaaah-abz6a-cai");
    };

    /// Helper to create a transfer
    public func createTransferArgs(from : Principal, to : Principal, amount : Nat) : TransferArgs {
        return {
            amount = amount;
            to = {
                owner = to;
                subaccount = ?principalToSubaccount(from);
            };
            created_at_time = ?Nat64.fromIntWrap(Time.now());

            from_subaccount = null;
            fee = null;
            memo = ?Text.encodeUtf8("Create neuron in Motoko Bootcamp Core-Project DAO");
        };
    };

    // Functions to convert principal to account copied from
    // https://github.com/Matlor/Information-Market/blob/1e53e574655cbf5297eddbb05f3f4006654f96ca/prototype/canisters/market/ledger/accounts.mo
    public func beBytes(n : Nat32) : [Nat8] {
        func byte(n : Nat32) : Nat8 {
            Nat8.fromNat(Nat32.toNat(n & 0xff));
        };
        [byte(n >> 24), byte(n >> 16), byte(n >> 8), byte(n)];
    };

    /// get account
    public func principalToSubaccount(principal : Principal) : Blob {
        let idHash = Sha224.Digest();
        idHash.write(Blob.toArray(Principal.toBlob(principal)));
        let hashSum = idHash.sum();
        let crc32Bytes = beBytes(CRC32.ofArray(hashSum));
        Blob.fromArray(Array.append(crc32Bytes, hashSum));
    };

};
