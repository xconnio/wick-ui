import "dart:convert";
import "dart:developer";
import "dart:io";
import "package:get/get.dart";
import "package:path_provider/path_provider.dart";

mixin StateManager {
  RxMap<String, bool> runningRouters = <String, bool>{}.obs;
  static const String _routerStateFile = "router_state.json";

  Future<void> initializeState() async {
    await _loadAllStates();
  }

  Future<void> cleanupState() async {
    await clearAllStates();
  }

  Future<void> _loadAllStates() async {
    await loadRouterState();
  }

  Future<void> saveAllStates() async {
    await saveRouterState();
  }

  Future<void> clearAllStates() async {
    await clearRouterState();
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
          state.map(
            (key, value) => MapEntry(key, value as bool),
          ),
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
        log("StateManagerMixin: Cleared router state file");
      } else {
        log("StateManagerMixin: No router state file to clear");
      }
      runningRouters.clear();
    } on Exception catch (e) {
      log("StateManagerMixin: Failed to clear router state: $e");
    }
  }
}
