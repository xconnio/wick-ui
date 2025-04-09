import "dart:developer";
import "package:wick_ui/app/data/models/profile_model.dart";
import "package:wick_ui/utils/state_manager.dart";
import "package:xconn/xconn.dart";

mixin SessionManager on StateManager {
  final Map<String, Session> activeSessions = {};

  Future<Session> connect(ProfileModel profile) async {
    if (activeSessions.containsKey(profile.name)) {
      log("SessionManager: Session for '${profile.name}' already active");
      return activeSessions[profile.name]!;
    }

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

    try {
      final session = await client.connect(profile.uri, profile.realm);
      activeSessions[profile.name] = session;
      profileSessions[profile.name] = true;
      await saveProfileState();
      log("SessionManager: Connected session for '${profile.name}'");
      return session;
    } on Exception catch (e) {
      activeSessions.remove(profile.name);
      profileSessions[profile.name] = false;
      await saveProfileState();
      log("SessionManager: Failed to connect or session closed for '${profile.name}': $e");
      rethrow;
    }
  }

  Future<void> disconnect(ProfileModel profile) async {
    final session = activeSessions[profile.name];
    if (session != null) {
      try {
        await session.close();
        log("SessionManager: Disconnected session for '${profile.name}'");
      } on Exception catch (e) {
        log("SessionManager: Session for '${profile.name}' already closed or error: $e");
      }
      activeSessions.remove(profile.name);
      profileSessions[profile.name] = false;
      await saveProfileState();
    } else {
      log("SessionManager: No active session for '${profile.name}' to disconnect");
    }
  }

  bool isConnected(ProfileModel profile) {
    return activeSessions.containsKey(profile.name);
  }

  Future<void> clearAllSessions() async {
    for (final session in activeSessions.values) {
      try {
        await session.close();
      } on Exception catch (e) {
        log("SessionManager: Error closing session during clear: $e");
      }
    }
    activeSessions.clear();
    profileSessions.clear();
    await clearProfileState();
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

  Future<void> restoreSessions(List<ProfileModel> profiles) async {
    log("SessionManager: Restoring sessions");
    for (final profile in profiles) {
      if ((profileSessions[profile.name] ?? false) && !activeSessions.containsKey(profile.name)) {
        try {
          await connect(profile);
          log("SessionManager: Restored session for '${profile.name}'");
        } on Exception catch (e) {
          profileSessions[profile.name] = false;
          await saveProfileState();
          log("SessionManager: Failed to restore session for '${profile.name}': $e");
        }
      }
    }
  }

  Future<void> validateSessions() async {
    log("SessionManager: Validating all active sessions");
    final profilesToCheck = activeSessions.keys.toList();
    for (final profileName in profilesToCheck) {
      final session = activeSessions[profileName];
      if (session != null) {
        try {
          await session.call("wamp.session.count");
          log("SessionManager: Session for '$profileName' is alive");
        } on Exception catch (e) {
          log("SessionManager: Session for '$profileName' is no longer alive: $e");
          activeSessions.remove(profileName);
          profileSessions[profileName] = false;
          await saveProfileState();
        }
      }
    }
  }
}
