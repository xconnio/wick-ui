import 'package:xconn/xconn.dart';

import '../app/data/models/profile_model.dart';

class SessionManager {
  static Future<Session> connect(ProfileModel profile) async {
    var serializer = _getSerializer(profile.serializer);

    Client client;
    if (profile.authmethod == 'Ticket') {
      client = Client(
          serializer: serializer,
          authenticator: TicketAuthenticator(profile.authid, {}, profile.secret));
    } else if (profile.authmethod == 'WAMP-CRA') {
      client = Client(
          serializer: serializer,
          authenticator: WAMPCRAAuthenticator(profile.authid, {}, profile.secret));
    } else if (profile.authmethod == 'CryptoSign') {
      client = Client(
          serializer: serializer,
          authenticator: CryptoSignAuthenticator(profile.authid, {}, profile.secret));
    } else if (profile.authmethod == 'Anonymous') {
      client = Client(
          serializer: serializer,
          authenticator: AnonymousAuthenticator(profile.authid));
    } else {
      client = Client(serializer: serializer);
    }

    return client.connect(profile.url, profile.realm);
  }

  static Serializer _getSerializer(String? serializerString) {
    switch (serializerString) {
      case 'JSON':
        return JSONSerializer();
      case 'CBOR':
        return CBORSerializer();
      case 'MsgPack':
        return MsgPackSerializer();
      default:
        throw Exception("Invalid serializer $serializerString");
    }
  }
}
