import "dart:developer";
import "package:wick_ui/app/data/models/client_model.dart";
import "package:wick_ui/utils/state_manager.dart";
import "package:xconn/xconn.dart";

mixin SessionManager on StateManager {
  final Map<String, Session> activeSessions = {};

  Future<Session> connect(ClientModel newClient) async {
    if (activeSessions.containsKey(newClient.name)) {
      log("SessionManager: Session for '${newClient.name}' already active");
      return activeSessions[newClient.name]!;
    }

    var serializer = _getSerializer(newClient.serializer);

    Client client;
    if (newClient.authmethod == "ticket") {
      client = Client(
        serializer: serializer,
        authenticator: TicketAuthenticator(newClient.authid, {}, newClient.secret),
      );
    } else if (newClient.authmethod == "wamp-cra") {
      client = Client(
        serializer: serializer,
        authenticator: WAMPCRAAuthenticator(newClient.authid, {}, newClient.secret),
      );
    } else if (newClient.authmethod == "cryptoSign") {
      client = Client(
        serializer: serializer,
        authenticator: CryptoSignAuthenticator(newClient.authid, {}, newClient.secret),
      );
    } else if (newClient.authmethod == "anonymous") {
      client = Client(
        serializer: serializer,
        authenticator: AnonymousAuthenticator(newClient.authid),
      );
    } else {
      client = Client(serializer: serializer);
    }

    try {
      final session = await client.connect(newClient.uri, newClient.realm);
      activeSessions[newClient.name] = session;
      clientSessions[newClient.name] = true;
      await saveClientState();
      log("SessionManager: Connected session for '${newClient.name}'");
      return session;
    } on Exception catch (e) {
      clientSessions[newClient.name] = false;
      await saveClientState();
      log("SessionManager: Failed to connect session for '${newClient.name}': $e");
      rethrow;
    }
  }

  Future<void> disconnect(ClientModel client) async {
    final session = activeSessions[client.name];
    if (session != null) {
      try {
        await session.close();
        log("SessionManager: Disconnected session for '${client.name}'");
      } on Exception catch (e) {
        log("SessionManager: Failed to close session for '${client.name}': $e");
      } finally {
        activeSessions.remove(client.name);
        clientSessions[client.name] = false;
        await saveClientState();
      }
    } else {
      log("SessionManager: No active session found for '${client.name}'");
      clientSessions[client.name] = false;
      await saveClientState();
    }
  }

  bool isConnected(ClientModel client) {
    final session = activeSessions[client.name];
    if (session == null) {
      return false;
    }
    return clientSessions[client.name] ?? false;
  }

  Future<void> clearAllSessions() async {
    for (final session in activeSessions.values) {
      try {
        await session.close();
      } on Exception catch (e) {
        log("SessionManager: Failed to close session during clearAllSessions: $e");
      }
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
          activeSessions.remove(client.name);
          clientSessions[client.name] = false;
          await saveClientState();
          log("SessionManager: Failed to restore session for '${client.name}': $e");
        }
      }
    }
  }
}
