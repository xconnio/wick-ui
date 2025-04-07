import "package:wick_ui/app/data/models/profile_model.dart";
import "package:xconn/xconn.dart";

mixin SessionManager {
  static Future<Session> connect(ProfileModel profile) async {
    var serializer = _getSerializer(profile.serializer);

    Client client;
    if (profile.authmethod == "ticket") {
      client = Client(
        serializer: serializer,
        authenticator: TicketAuthenticator(profile.authid, {}, profile.secret),
      );
    } else if (profile.authmethod == "wamp-cra") {
      client = Client(
        serializer: serializer,
        authenticator: WAMPCRAAuthenticator(profile.authid, {}, profile.secret),
      );
    } else if (profile.authmethod == "cryptoSign") {
      client = Client(
        serializer: serializer,
        authenticator: CryptoSignAuthenticator(profile.authid, {}, profile.secret),
      );
    } else if (profile.authmethod == "anonymous") {
      client = Client(
        serializer: serializer,
        authenticator: AnonymousAuthenticator(profile.authid),
      );
    } else {
      client = Client(serializer: serializer);
    }

    return client.connect(profile.uri, profile.realm);
  }

  static Serializer _getSerializer(String? serializerString) {
    switch (serializerString) {
      case "json":
        return JSONSerializer();
      case "cbor":
        return CBORSerializer();
      case "msgpack":
        return MsgPackSerializer();
      default:
        throw Exception("Invalid serializer $serializerString");
    }
  }
}
