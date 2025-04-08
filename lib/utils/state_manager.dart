import "dart:convert";
import "dart:developer";
import "dart:io";
import "package:get/get.dart";
import "package:path_provider/path_provider.dart";

mixin StateManager {
  RxMap<String, bool> runningRouters = <String, bool>{}.obs;
  RxMap<String, bool> profileSessions = <String, bool>{}.obs;
  static const String _routerStateFile = "router_state.json";
  static const String _profileStateFile = "profile_state.json";

  Future<void> initializeState() async {
    await _loadAllStates();
  }

  Future<void> cleanupState() async {
    await clearAllStates();
  }

  Future<void> _loadAllStates() async {
    await loadRouterState();
    await loadProfileState();
  }

  Future<void> saveAllStates() async {
    await saveRouterState();
    await saveProfileState();
  }

  Future<void> clearAllStates() async {
    await clearRouterState();
    await clearProfileState();
  }

  Future<void> saveRouterState() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File("${directory.path}/$_routerStateFile");
      final state = runningRouters.toJson();
      await file.writeAsString(json.encode(state));
    } on Exception catch (e) {
      log("Failed to save router state: $e");
    }
  }

  Future<void> loadRouterState() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File("${directory.path}/$_routerStateFile");
      if (file.existsSync()) {
        final stateString = await file.readAsString();
        final state = json.decode(stateString) as Map<String, dynamic>;
        runningRouters.value = RxMap<String, bool>.from(
          state.map((key, value) => MapEntry(key, value as bool)),
        );
      }
    } on Exception catch (e) {
      log("Failed to load router state: $e");
    }
  }

  Future<void> clearRouterState() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File("${directory.path}/$_routerStateFile");
      if (file.existsSync()) {
        await file.delete();
        log("StateManager: Cleared router state file");
      } else {
        log("StateManager: No router state file to clear");
      }
      runningRouters.clear();
    } on Exception catch (e) {
      log("StateManager: Failed to clear router state: $e");
    }
  }

  Future<void> saveProfileState() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File("${directory.path}/$_profileStateFile");
      final state = profileSessions.toJson();
      await file.writeAsString(json.encode(state));
    } on Exception catch (e) {
      log("Failed to save profile state: $e");
    }
  }

  Future<void> loadProfileState() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File("${directory.path}/$_profileStateFile");
      if (file.existsSync()) {
        final stateString = await file.readAsString();
        final state = json.decode(stateString) as Map<String, dynamic>;
        profileSessions.value = RxMap<String, bool>.from(
          state.map((key, value) => MapEntry(key, value as bool)),
        );
      }
    } on Exception catch (e) {
      log("Failed to load profile state: $e");
    }
  }

  Future<void> clearProfileState() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File("${directory.path}/$_profileStateFile");
      if (file.existsSync()) {
        await file.delete();
        log("StateManager: Cleared profile state file");
      } else {
        log("StateManager: No profile state file to clear");
      }
      profileSessions.clear();
    } on Exception catch (e) {
      log("StateManager: Failed to clear profile state: $e");
    }
  }
}
