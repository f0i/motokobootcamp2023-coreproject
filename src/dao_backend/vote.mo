// @verify

import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";

module Vote {

    public type Decision = { #support; #decline };

    /// Information about one vote
    public type Vote = {
        decision : Decision;
        date : Time.Time;
    };

    /// Return a new vote
    public func init(decision : Decision) : Vote {
        return {
            decision;
            date = Time.now();
        };
    };

};
