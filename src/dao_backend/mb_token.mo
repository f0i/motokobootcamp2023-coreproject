import Principal "mo:base/Principal";
import Blob "mo:base/Blob";

module MbToken {
    type Subaccount = Blob.Blob;
    type Account = { owner : Principal; subaccount : ?Subaccount };

    public func getCanister() : actor {
        icrc1_balance_of : (Principal) -> async Nat;
        icrc1_name : () -> async Text;
        icrc1_symbol : () -> async Text;
    } {
        return actor ("db3eq-6iaaa-aaaah-abz6a-cai");
    };

};
