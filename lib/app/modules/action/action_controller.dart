import "dart:async";
import "dart:developer";
import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:wick_ui/app/data/models/client_model.dart";
import "package:wick_ui/app/modules/client/client_controller.dart";
import "package:xconn/xconn.dart";

class ActionController extends GetxController {
  final Rx<ClientModel?> selectedClient = Rx<ClientModel?>(null);
  final RxList<String> logs = <String>[].obs;
  final RxString errorMessage = "".obs;
  final RxString selectedMethod = "Call".obs;
  final RxBool isActionInProgress = false.obs;

  late TextEditingController uriController;
  final ClientController clientController = Get.find<ClientController>();
  StreamSubscription? _subscription;
  final int _maxLogs = 1000;
  final int _maxRetries = 1;

  @override
  void onInit() {
    super.onInit();
    uriController = TextEditingController();
    trySetInitialClient();
  }

  @override
  Future<void> onClose() async {
    await _cleanUpResources();
    super.onClose();
  }

  Future<void> _cleanUpResources() async {
    uriController.dispose();
    await _subscription?.cancel();
    logs.clear();
    log("ActionController resources cleaned up");
  }

  void trySetInitialClient() {
    try {
      final connectedClient = clientController.clients.firstWhereOrNull(
        clientController.isConnected,
      );
      if (connectedClient != null) {
        selectedClient.value = connectedClient;
      }
    } on Exception catch (e) {
      log("Error setting initial client: $e");
    }
  }

  Future<void> setSelectedClient(ClientModel client) async {
    if (selectedClient.value == client) {
      return;
    }

    selectedClient.value = client;
    if (!clientController.isConnected(client)) {
      await _handleClientReconnection(client);
    }
  }

  Future<void> _handleClientReconnection(ClientModel client) async {
    try {
      _addLog("Attempting to connect client '${client.name}'...");
      await clientController.connect(client);
      _addLog("Client '${client.name}' connected successfully");
    } catch (e) {
      final errorMsg = "Failed to connect client '${client.name}': $e";
      errorMessage.value = errorMsg;
      _addLog("Error: $errorMsg");
      rethrow;
    }
  }

  String _getCurrentTimestamp() {
    return DateTime.now().toIso8601String();
  }

  void _addLog(String message) {
    if (logs.length >= _maxLogs) {
      logs.removeAt(0);
    }
    logs.add("${_getCurrentTimestamp()} - $message");
  }

  void clearLogs() {
    logs.clear();
    _addLog("Logs cleared");
  }

  Future<void> performAction(
    String actionType,
    String uri,
    List<String> args,
    Map<String, String> kwArgs,
  ) async {
    if (isActionInProgress.value) {
      return;
    }
    isActionInProgress.value = true;

    try {
      await _performActionInternal(
        actionType,
        uri,
        _sanitizeArgs(args),
        _sanitizeKwArgs(kwArgs),
      );
    } on Exception catch (e) {
      errorMessage.value = "Unexpected error: $e";
      _addLog("Critical Error: $e");
    } finally {
      isActionInProgress.value = false;
    }
  }

  List<String> _sanitizeArgs(List<String> args) {
    return args.where((arg) => arg.trim().isNotEmpty).toList();
  }

  Map<String, String> _sanitizeKwArgs(Map<String, String> kwArgs) {
    return Map.from(kwArgs)..removeWhere((k, v) => k.trim().isEmpty && v.trim().isEmpty);
  }

  Future<void> _performActionInternal(
    String actionType,
    String uri,
    List<String> args,
    Map<String, String> kwArgs,
  ) async {
    errorMessage.value = "";
    selectedMethod.value = actionType.toLowerCase().capitalizeFirst!;

    if (selectedClient.value == null) {
      _handleError("Please select a client first.");
      return;
    }

    final client = selectedClient.value!;
    Session session;
    try {
      session = await clientController.getOrCreateSession(client);
    } on Exception catch (e) {
      _handleError("Failed to establish session for client '${client.name}': $e");
      return;
    }

    if (uri.isEmpty) {
      _handleError("URI cannot be empty.");
      return;
    }

    _addLog("Starting $actionType action on URI: $uri");
    final result = await _executeWampAction(
      actionType,
      session,
      uri,
      args,
      kwArgs,
    );

    if (result.error != null) {
      _handleError(result.error!);
    } else {
      _addLog("Success: ${result.data}");
    }
  }

  void _handleError(String message) {
    errorMessage.value = message;
    _addLog("Error: $message");
  }

  Future<Logs> _executeWampAction(
    String actionType,
    Session session,
    String uri,
    List<String> args,
    Map<String, String> kwArgs,
  ) async {
    int retryCount = 0;

    try {
      return await Future.any([
        Future(() async {
          while (retryCount <= _maxRetries) {
            try {
              switch (actionType.toLowerCase()) {
                case "call":
                  return await _performCallAction(session, uri, args, kwArgs);
                case "register":
                  return await _performRegisterAction(session, uri, args);
                case "subscribe":
                  return await _performSubscribeAction(session, uri);
                case "publish":
                  return await _performPublishAction(session, uri, args, kwArgs);
                default:
                  return Logs(error: "Unknown action type: $actionType");
              }
            } on Exception catch (e) {
              if (retryCount < _maxRetries) {
                retryCount++;
                await clientController.disconnect(selectedClient.value!);
                await clientController.getOrCreateSession(selectedClient.value!);
                continue;
              }
              return Logs(error: "Failed to perform $actionType after retries: $e");
            }
          }
          return Logs(error: "Failed to perform $actionType after retrying");
        }),
        Future.delayed(const Duration(seconds: 15), () {
          throw TimeoutException("Action $actionType timed out after 15 seconds");
        }),
      ]);
    } on Exception catch (e) {
      return Logs(error: "Failed to execute action: $e");
    }
  }

  Future<Logs> _performCallAction(
    Session session,
    String uri,
    List<String> args,
    Map<String, String> kwArgs,
  ) async {
    try {
      final result = await session.call(uri, args: args, kwargs: kwArgs);
      return Logs(data: "Call result - args: ${result.args}, kwargs: ${result.kwargs}");
    } on Exception {
      rethrow;
    }
  }

  Future<Logs> _performRegisterAction(
    Session session,
    String uri,
    List<String> args,
  ) async {
    try {
      final result = await session.register(uri, (Invocation inv) {
        return Result(args: inv.args, kwargs: inv.kwargs);
      });
      return Logs(data: "Registered procedure: $result");
    } on Exception {
      rethrow;
    }
  }

  Future<Logs> _performSubscribeAction(
    Session session,
    String uri,
  ) async {
    try {
      await _subscription?.cancel();
      _subscription = session
          .subscribe(uri, (event) {
            _addLog("Event received - args: ${event.args}, kwargs: ${event.kwargs}");
          })
          .asStream()
          .listen(null);
      return Logs(data: "Subscribed to topic: $uri");
    } on Exception {
      rethrow;
    }
  }

  Future<Logs> _performPublishAction(
    Session session,
    String uri,
    List<String> args,
    Map<String, String> kwArgs,
  ) async {
    try {
      await session.publish(uri, args: args, kwargs: kwArgs);
      return Logs(data: "Published to topic: $uri");
    } on Exception {
      rethrow;
    }
  }
}

class Logs {
  Logs({this.data, this.error});

  final String? data;
  final String? error;
}
