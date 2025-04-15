import "dart:developer" as dev;
import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:wick_ui/app/data/models/client_model.dart";
import "package:wick_ui/app/modules/client/client_controller.dart";
import "package:xconn/xconn.dart";

class ActionController extends GetxController {
  ActionController() {
    uriController = TextEditingController();
  }
  Rx<ClientModel?> selectedClient = Rx<ClientModel?>(null);
  RxString uri = "".obs;
  RxString selectedWampMethod = "".obs;
  RxString logsMessage = "".obs;

  final ClientController clientController = Get.find<ClientController>();
  late TextEditingController uriController;

  @override
  void onInit() {
    super.onInit();
    dev.log("ActionController: Initialized");
  }

  @override
  void onClose() {
    uriController.dispose();
    dev.log("ActionController: Closed, uriController disposed");
    super.onClose();
  }

  Future<void> setSelectedClient(ClientModel client) async {
    selectedClient.value = client;
    if (!clientController.isConnected(client) && (clientController.clientSessions[client.name] ?? false)) {
      await clientController.connect(client);
    }
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
    if (selectedClient.value == null) {
      _addLog("Please select a client first.");
      return;
    }

    try {
      Logs result;
      var argsEmpty = true;
      for (final arg in args) {
        if (arg.trim().isNotEmpty) {
          argsEmpty = false;
          break;
        }
      }
      if (argsEmpty) {
        args.clear();
      }

      var kwargsEmpty = true;
      kwArgs.forEach((String key, String value) {
        if (key.trim().isNotEmpty || value.trim().isNotEmpty) {
          kwargsEmpty = false;
        }
      });
      if (kwargsEmpty) {
        kwArgs.clear();
      }

      final session = clientController.isConnected(selectedClient.value!)
          ? clientController.activeSessions[selectedClient.value!.name]!
          : await clientController.connect(selectedClient.value!);

      switch (actionType) {
        case "Call":
          result = await performCallAction(session, uri, args, kwArgs);
        case "Register":
          result = await performRegisterAction(session, uri, args);
        case "Subscribe":
          result = await performSubscribeAction(session, uri);
        case "Publish":
          result = await performPublishAction(session, uri, args, kwArgs);
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
  }

  Future<Logs> performCallAction(
    Session session,
    String uri,
    List<String> args,
    Map<String, String> kwArgs,
  ) async {
    try {
      final result = await session.call(uri, args: args, kwargs: kwArgs);
      return Logs(data: "args=${result.args}, kwargs=${result.kwargs}");
    } on Exception catch (e) {
      return Logs(error: "Failed to perform call: $e");
    }
  }

  Future<Logs> performRegisterAction(Session session, String uri, List<String> args) async {
    try {
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

  Future<Logs> performSubscribeAction(Session session, String uri) async {
    try {
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

  Future<Logs> performPublishAction(
    Session session,
    String uri,
    List<String> args,
    Map<String, String> kwArgs,
  ) async {
    try {
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
