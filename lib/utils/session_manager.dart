import "dart:async";
import "dart:developer";
import "package:wick_ui/app/data/models/client_model.dart";
import "package:wick_ui/utils/state_manager.dart";
import "package:xconn/xconn.dart";

mixin SessionManager on StateManager {
  Session? _currentSession;
  Timer? _keepAliveTimer;

  Future<Session> connect(ClientModel newClient) async {
    log("SessionManager: Attempting to connect for '${newClient.name}'");

    await _closeCurrentSession();

    var serializer = _getSerializer(newClient.serializer);

    Client client;
    if (newClient.authmethod == "ticket") {
      client = Client(
        config: ClientConfig(
          serializer: serializer,
          authenticator: TicketAuthenticator(newClient.authid, {}, newClient.secret),
          keepAliveInterval: const Duration(seconds: 10), // Reduced interval
        ),
      );
    } else if (newClient.authmethod == "wamp-cra") {
      client = Client(
        config: ClientConfig(
          serializer: serializer,
          authenticator: WAMPCRAAuthenticator(newClient.authid, {}, newClient.secret),
          keepAliveInterval: const Duration(seconds: 10),
        ),
      );
    } else if (newClient.authmethod == "cryptoSign") {
      client = Client(
        config: ClientConfig(
          serializer: serializer,
          authenticator: CryptoSignAuthenticator(newClient.authid, {}, newClient.secret),
          keepAliveInterval: const Duration(seconds: 10),
        ),
      );
    } else if (newClient.authmethod == "anonymous") {
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
      _currentSession = await client.connect(newClient.uri, newClient.realm);
      clientSessions[newClient.name] = true;
      _startKeepAlive(newClient);
      log("SessionManager: Connected session for '${newClient.name}', _currentSession: $_currentSession");
      return _currentSession!;
    } on Exception catch (e) {
      clientSessions[newClient.name] = false;
      log("SessionManager: Failed to connect session for '${newClient.name}': $e");
      rethrow;
    }
  }

  Future<void> disconnect(ClientModel client) async {
    if (_currentSession != null) {
      try {
        await _currentSession!.close();
        log("SessionManager: Disconnected session for '${client.name}'");
      } on Exception catch (e) {
        log("SessionManager: Failed to close session for '${client.name}': $e");
      } finally {
        _currentSession = null;
        clientSessions[client.name] = false;
        _stopKeepAlive();
      }
    } else {
      log("SessionManager: No active session found for '${client.name}'");
      clientSessions[client.name] = false;
      _stopKeepAlive();
    }
  }

  Future<bool> _isSessionValid(Session session) async {
    try {
      await session.call("wamp.session.count", args: []).timeout(const Duration(seconds: 5));
      log("SessionManager: Session validated successfully");
      return true;
    } on Exception catch (e) {
      log("SessionManager: Session validation failed: $e");
      return false;
    }
  }

  bool isConnected(ClientModel client) {
    return _currentSession != null && (clientSessions[client.name] ?? false);
  }

  Future<void> clearAllSessions() async {
    await _closeCurrentSession();
    clientSessions.clear();
    _stopKeepAlive();
    log("SessionManager: Cleared all sessions");
  }

  Future<void> _closeCurrentSession() async {
    if (_currentSession != null) {
      try {
        await _currentSession!.close();
      } on Exception catch (e) {
        log("SessionManager: Failed to close current session: $e");
      } finally {
        _currentSession = null;
      }
    }
  }

  void _startKeepAlive(ClientModel client) {
    _stopKeepAlive();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (_currentSession != null && isConnected(client)) {
        try {
          await _currentSession!.call("wamp.session.count", args: []).timeout(const Duration(seconds: 3));
          log("SessionManager: Keep-alive ping successful for '${client.name}'");
        } on Exception catch (e) {
          log("SessionManager: Keep-alive ping failed for '${client.name}': $e");
          await disconnect(client);
          await connect(client);
        }
      }
    });
  }

  void _stopKeepAlive() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
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
      if ((clientSessions[client.name] ?? false) && _currentSession == null) {
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

  Future<Session> getOrCreateSession(ClientModel client) async {
    if (_currentSession == null || !isConnected(client)) {
      log("SessionManager: No session or not connected for '${client.name}', creating new session");
      return connect(client);
    }

    if (!(await _isSessionValid(_currentSession!))) {
      log("SessionManager: Invalid session detected for '${client.name}', forcing reconnect");
      await _closeCurrentSession();
      return connect(client);
    }

    log("SessionManager: Reusing valid session for '${client.name}', _currentSession: $_currentSession");
    return _currentSession!;
  }
}
