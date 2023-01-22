import Http "http";
import Text "mo:base/Text";
import CertifiedData "mo:base/CertifiedData";
import HashTree "hash_tree";
import Principal "mo:base/Principal";

shared ({ caller = admin }) actor class Main() = this {
  public type HttpReq = Http.HttpRequest;
  public type HttpRes = Http.HttpResponse;

  stable var current_text : Blob = Text.encodeUtf8("");

  /// ID of the dao_backend canister
  let dao_backend = Principal.fromText("6x4s2-6yaaa-aaaah-ab4gq-cai");
  let dao_backend_local = Principal.fromText("qsgjb-riaaa-aaaaa-aaaga-cai");

  /// Set a new string
  /// can only be called from the dao_backend
  public shared ({ caller }) func update_text(new_text : Text) : async () {
    assert (caller == dao_backend or caller == dao_backend_local);

    current_text := Text.encodeUtf8(new_text);
    update_verified_vars();
  };

  /// HTTP request handler
  public query func http_request(req : HttpReq) : async HttpRes {
    return ({
      body = current_text;
      headers = [
        ("content-type", "text/plain"),
        HashTree.certification_header(current_text),
      ];
      status_code = 200;
      streaming_strategy = null;
    });
  };

  /// verify vars after each upgrade
  system func postupgrade() {
    update_verified_vars();
  };

  /// call function to update verification of vars
  private func update_verified_vars() {
    HashTree.update_asset_hash(current_text);
  };

};
