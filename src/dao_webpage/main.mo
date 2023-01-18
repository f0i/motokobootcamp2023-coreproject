import Http "http";
import Text "mo:base/Text";
import CertifiedData "mo:base/CertifiedData";
import HashTree "hash_tree";

actor {
  public type HttpReq = Http.HttpRequest;
  public type HttpRes = Http.HttpResponse;

  stable var current_text : Blob = Text.encodeUtf8("");

  public func update_text(new_text : Text) : async () {
    current_text := Text.encodeUtf8(new_text);
    update_verified_vars();
  };

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

  system func postupgrade() {

    update_verified_vars();
  };

  private func update_verified_vars() {
    HashTree.update_asset_hash(current_text);
  };

};
