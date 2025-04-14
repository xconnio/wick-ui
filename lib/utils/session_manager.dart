import "dart:developer";
import "package:wick_ui/app/data/models/client_model.dart";
import "package:wick_ui/utils/state_manager.dart";
import "package:xconn/xconn.dart";

mixin SessionManager on StateManager {
  final Map<String, Session> activeSessions = {};

  Future<Session> connect(ClientModel new_client) async {
    if (activeSessions.containsKey(new_client.name)) {
      log("SessionManager: Session for '${new_client.name}' already active");
      return activeSessions[new_client.name]!;
    }

    var serializer = _getSerializer(new_client.serializer);

    Client client;
    if (new_client.authmethod == "ticket") {
      client = Client(
        serializer: serializer,
        authenticator: TicketAuthenticator(new_client.authid, {}, new_client.secret),
      );
    } else if (new_client.authmethod == "wamp-cra") {
      client = Client(
        serializer: serializer,
        authenticator: WAMPCRAAuthenticator(new_client.authid, {}, new_client.secret),
      );
    } else if (new_client.authmethod == "cryptoSign") {
      client = Client(
        serializer: serializer,
        authenticator: CryptoSignAuthenticator(new_client.authid, {}, new_client.secret),
      );
    } else if (new_client.authmethod == "anonymous") {
      client = Client(
        serializer: serializer,
        authenticator: AnonymousAuthenticator(new_client.authid),
      );
    } else {
      client = Client(serializer: serializer);
    }

    final session = await client.connect(new_client.uri, new_client.realm);
    activeSessions[new_client.name] = session;
    clientSessions[new_client.name] = true;
    await saveClientState();
    log("SessionManager: Connected session for '${new_client.name}'");
    return session;
  }

  Future<void> disconnect(ClientModel client) async {
    final session = activeSessions[client.name];
    if (session != null) {
      await session.close();
      activeSessions.remove(client.name);
      clientSessions[client.name] = false;
      await saveClientState();
      log("SessionManager: Disconnected session for '${client.name}'");
    }
  }

  bool isConnected(ClientModel client) {
    return activeSessions.containsKey(client.name);
  }

  Future<void> clearAllSessions() async {
    for (final session in activeSessions.values) {
      await session.close();
    }
    activeSessions.clear();
    clientSessions.clear();
    await clearClientState();
    log("SessionManager: Cleared all sessions");
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

  Future<void> restoreSessions(List<ClientModel> clients) async {
    log("SessionManager: Restoring sessions");
    for (final client in clients) {
      if ((clientSessions[client.name] ?? false) && !activeSessions.containsKey(client.name)) {
        try {
          await connect(client);
          log("SessionManager: Restored session for '${client.name}'");
        } on Exception catch (e) {
          clientSessions[client.name] = false;
          await saveClientState();
          log("SessionManager: Failed to restore session for '${client.name}': $e");
        }
      }
    }
  }
}
