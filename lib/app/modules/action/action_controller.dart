import "package:get/get.dart";
import "package:wick_ui/app/data/models/profile_model.dart";
import "package:wick_ui/utils/session_manager.dart";
import "package:xconn/xconn.dart";

class ActionController extends GetxController {
  Rx<ProfileModel?> selectedProfile = Rx<ProfileModel?>(null);
  RxString uri = "".obs;
  RxString selectedWampMethod = "".obs;
  RxString logsMessage = "".obs;

  Future<void> setSelectedProfile(ProfileModel profile) async {
    selectedProfile.value = profile;
  }

  String _getCurrentTimestamp() {
    final now = DateTime.now();
    return now.toIso8601String();
  }

  void _addLog(String message) {
    logsMessage.value += "${_getCurrentTimestamp()} - $message\n";
  }

  Future<void> performAction(
    String actionType,
    String uri,
    List<String> args,
    Map<String, String> kwArgs,
  ) async {
    if (selectedProfile.value != null) {
      try {
        Logs result;
        switch (actionType) {
          case "Call":
            result = await performCallAction(uri, args, kwArgs);
          case "Register":
            result = await performRegisterAction(uri, args);
          case "Subscribe":
            result = await performSubscribeAction(uri);
          case "Publish":
            result = await performPublishAction(uri, args, kwArgs);
          default:
            result = Logs(error: "Select Action");
        }

        if (result.error != null) {
          _addLog("Error: ${result.error}");
        } else {
          _addLog("Success: ${result.data}");
        }
      } on Exception catch (e) {
        _addLog("An exception occurred: $e");
      }
    } else {
      _addLog("Please select a profile first.");
    }
  }

  Future<Logs> performCallAction(
    String uri,
    List<String> args,
    Map<String, String> kwArgs,
  ) async {
    try {
      final session = await SessionManager.connect(selectedProfile.value!);
      final result = await session.call(uri, args: args, kwargs: kwArgs);
      return Logs(data: "args=${result.args}, kwargs=${result.kwargs}");
    } on Exception catch (e) {
      return Logs(error: "Failed to perform call: $e");
    }
  }

  Future<Logs> performRegisterAction(String uri, List<String> args) async {
    try {
      final session = await SessionManager.connect(selectedProfile.value!);
      final result = await session.register(uri, (Invocation inv) {
        final response = Result(args: inv.args, kwargs: inv.kwargs);
        _addLog("Register invoked with args=${inv.args}, kwargs=${inv.kwargs}");
        return response;
      });
      return Logs(data: "Register action performed successfully: $result");
    } on Exception catch (e) {
      return Logs(error: "Failed to perform register: $e");
    }
  }

  Future<Logs> performSubscribeAction(String uri) async {
    try {
      final session = await SessionManager.connect(selectedProfile.value!);
      await session.subscribe(uri, (event) {
        _addLog(
          "Subscribed event received: args=${event.args}, kwargs=${event.kwargs}",
        );
      });
      return Logs(data: "Subscribed successfully");
    } on Exception catch (e) {
      return Logs(error: "Failed to subscribe: $e");
    }
  }

  Future<Logs> performPublishAction(String uri, List<String> args, Map<String, String> kwArgs) async {
    try {
      final session = await SessionManager.connect(selectedProfile.value!);
      await session.publish(uri, args: args, kwargs: kwArgs);
      return Logs(data: "Publish action performed successfully");
    } on Exception catch (e) {
      return Logs(error: "Failed to publish: $e");
    }
  }
}

class Logs {
  Logs({this.data, this.error});

  final String? data;
  final String? error;
}
