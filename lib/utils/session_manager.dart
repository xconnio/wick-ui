import "dart:async";
import "dart:developer";
import "package:wick_ui/app/data/models/client_model.dart";
import "package:wick_ui/utils/state_manager.dart";
import "package:xconn/xconn.dart";

mixin SessionManager on StateManager {
  Session? currentSession;
  String? _currentClientName;

  Future<Session> connect(ClientModel newClient) async {
    log("SessionManager: Attempting to connect for '${newClient.name}'");

    var serializer = _getSerializer(newClient.serializer);

    Client client;
    if (newClient.authmethod == "Ticket") {
      client = Client(
        config: ClientConfig(
          serializer: serializer,
          authenticator: TicketAuthenticator(newClient.authid, {}, newClient.secret),
          keepAliveInterval: const Duration(seconds: 10),
        ),
      );
    } else if (newClient.authmethod == "WAMP-CRA") {
      client = Client(
        config: ClientConfig(
          serializer: serializer,
          authenticator: WAMPCRAAuthenticator(newClient.authid, {}, newClient.secret),
          keepAliveInterval: const Duration(seconds: 10),
        ),
      );
    } else if (newClient.authmethod == "CryptoSign") {
      client = Client(
        config: ClientConfig(
          serializer: serializer,
          authenticator: CryptoSignAuthenticator(newClient.authid, {}, newClient.secret),
          keepAliveInterval: const Duration(seconds: 10),
        ),
      );
    } else if (newClient.authmethod == "Anonymous") {
      client = Client(
        config: ClientConfig(
          serializer: serializer,
          authenticator: AnonymousAuthenticator(newClient.authid),
          keepAliveInterval: const Duration(seconds: 10),
        ),
      );
    } else {
      client = Client(
        config: ClientConfig(
          serializer: serializer,
          keepAliveInterval: const Duration(seconds: 10),
        ),
      );
    }

    try {
      currentSession = await client.connect(newClient.uri, newClient.realm);
      clientSessions[newClient.name] = true;
      log("SessionManager: Connected session for '${newClient.name}', currentSession: $currentSession");
      return currentSession!;
    } on Exception catch (e) {
      clientSessions[newClient.name] = false;
      log("SessionManager: Failed to connect session for '${newClient.name}': $e");
      rethrow;
    }
  }

  Future<void> disconnect(ClientModel client) async {
    if (currentSession != null) {
      try {
        await currentSession!.close();
        log("SessionManager: Disconnected session for '${client.name}'");
      } on Exception catch (e) {
        log("SessionManager: Failed to close session for '${client.name}': $e");
      } finally {
        currentSession = null;
        clientSessions[client.name] = false;
      }
    } else {
      log("SessionManager: No active session found for '${client.name}'");
      clientSessions[client.name] = false;
    }
  }

  bool isConnected(ClientModel client) {
    return currentSession != null && (clientSessions[client.name] ?? false);
  }

  static Serializer _getSerializer(String? serializerString) {
    switch (serializerString) {
      case "JSON":
        return JSONSerializer();
      case "CBOR":
        return CBORSerializer();
      case "MSGPACK":
        return MsgPackSerializer();
      default:
        throw Exception("Invalid serializer $serializerString");
    }
  }

  Future<void> restoreSessions(List<ClientModel> clients) async {
    log("SessionManager: Restoring sessions");
    for (final client in clients) {
      if ((clientSessions[client.name] ?? false) && currentSession == null) {
        try {
          await connect(client);
          log("SessionManager: Restored session for '${client.name}'");
        } on Exception catch (e) {
          clientSessions[client.name] = false;
          log("SessionManager: Failed to restore session for '${client.name}': $e");
        }
      }
    }
  }

  Future<Session?> getOrCreateSession(ClientModel client) async {
    if (_currentClientName != null && _currentClientName != client.name && currentSession != null) {
      await disconnect(client);
      currentSession = null;
      clientSessions[_currentClientName!] = false;
      _currentClientName = null;
    }

    if (currentSession != null && _currentClientName == client.name && (clientSessions[client.name] ?? false)) {
      return currentSession;
    }

    log("SessionManager: '${client.name}' unavailable or not connected, creating new session");
    final session = await connect(client);
    _currentClientName = client.name;
    return session;
  }
}
