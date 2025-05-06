import "dart:async";

import "package:wick_ui/utils/constants.dart";
import "package:xconn/xconn.dart";

Serializer _getSerializer(String? serializerString) {
  switch (serializerString) {
    case jsonSerializer:
      return JSONSerializer();
    case cborSerializer:
      return CBORSerializer();
    case msgPackSerializer:
      return MsgPackSerializer();
    default:
      throw Exception("invalid serializer $serializerString");
  }
}

Future<Session> connect(
  String url,
  String realm,
  String serializerStr, {
  String? authid,
  String? authrole,
  String? ticket,
  String? secret,
  String? privateKey,
}) async {
  var serializer = _getSerializer(serializerStr);
  Client client;

  if (ticket != null) {
    client = Client(
      config: ClientConfig(
        serializer: serializer,
        authenticator: TicketAuthenticator(authid ?? "", {}, ticket),
      ),
    );
  } else if (secret != null) {
    client = Client(
      config: ClientConfig(
        serializer: serializer,
        authenticator: WAMPCRAAuthenticator(authid ?? "", {}, secret),
      ),
    );
  } else if (privateKey != null) {
    client = Client(
      config: ClientConfig(
        serializer: serializer,
        authenticator: CryptoSignAuthenticator(authid ?? "", {}, privateKey),
      ),
    );
  } else if (authid != null) {
    client = Client(
      config: ClientConfig(
        serializer: serializer,
        authenticator: AnonymousAuthenticator(authid),
      ),
    );
  } else {
    client = client = Client(config: ClientConfig(serializer: serializer));
  }

  return client.connect(url, realm);
}

Server startRouter(String host, int port, List<String> realms) {
  var r = Router();
  realms.forEach(r.addRealm);
  var server = Server(r);
  unawaited(server.start(host, port));
  return server;
}
