import "dart:async";
import "dart:convert";
import "dart:developer";
import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:wick_ui/app/data/models/client_model.dart";
import "package:wick_ui/app/modules/client/client_controller.dart";
import "package:wick_ui/utils/tab_container_controller.dart";
import "package:xconn/xconn.dart";

class ActionController extends GetxController {
  final String instanceId = DateTime.now().millisecondsSinceEpoch.toString();
  bool _isRefreshing = false;
  final Rx<ClientModel?> selectedClient = Rx<ClientModel?>(null);
  final RxList<String> logs = <String>[].obs;
  final RxString errorMessage = "".obs;
  final RxString selectedMethod = "Call".obs;
  final RxBool isActionInProgress = false.obs;
  final RxBool isInitialized = false.obs;
  String? tag;

  final Map<String, Registration> registrations = {};
  final Map<String, Subscription> subscriptions = {};

  late TextEditingController uriController;
  final ClientController clientController = Get.find<ClientController>();
  StreamSubscription? _subscription;
  final int _maxLogs = 1000;

  @override
  void onInit() {
    super.onInit();
    uriController = TextEditingController();
    trySetInitialClient();
    isInitialized.value = true;

    ever(selectedClient, (client) {
      if (client != null) {
        _updateTabName(client.name);
      }
    });
  }

  void _updateTabName(String clientName) {
    final tabStateController = Get.find<TabStateController>();
    final actionTag = tag?.split("_").last;
    final tabKey = int.tryParse(actionTag ?? "");

    if (tabKey != null) {
      tabStateController.updateClientName(tabKey, clientName);
    }
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

    final client = selectedClient.value;
    if (client == null) {
      return;
    }

    try {
      final session = await clientController.getOrCreateSession(client);

      for (final reg in registrations.values) {
        await session?.unregister(reg);
      }
      registrations.clear();

      for (final sub in subscriptions.values) {
        await session?.unsubscribe(sub);
      }
      subscriptions.clear();
    } on Exception catch (e) {
      _addLog("Cleanup error: $e");
    }
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
  }

  Future<void> performAction(
    String actionType,
    String uri,
    List<String> args,
    Map<String, String> kwArgs,
  ) async {
    if (!isInitialized.value || isActionInProgress.value) {
      return;
    }
    isActionInProgress.value = true;

    if (uri.isEmpty) {
      _addLog("URI cannot be empty.");
      isActionInProgress.value = false;
      update();
      return;
    }

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
      update();
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

    final client = selectedClient.value!;
    Session? session;
    try {
      session = await clientController.getOrCreateSession(client);
      if (session == null) {
        session = await clientController.getOrCreateSession(client);
        if (session == null) {
          _addLog("Failed to establish session after retry for client '${client.name}'");
          errorMessage.value = "No active session available.";
          return;
        }
      }
    } on Exception catch (e) {
      _addLog("Failed to establish session for client '${client.name}': $e");
      clientController.currentSession = null;
      return;
    }

    final result = await _executeWampAction(
      actionType,
      session,
      uri,
      args,
      kwArgs,
    ).timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        _addLog("Action timed out for URI: $uri");
        throw Exception("Request timed out");
      },
    );

    if (result.error != null) {
      _addLog(result.error!);
    } else {
      _addLog("Success: ${result.data}");
    }
  }

  Future<Logs> _executeWampAction(
    String actionType,
    Session session,
    String uri,
    List<String> args,
    Map<String, String> kwArgs,
  ) async {
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
        case "unregister":
          return await _performUnregisterAction(session, uri);
        case "unsubscribe":
          return await _performUnsubscribeAction(session, uri);
        default:
          throw Exception("Unknown action type: $actionType");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Logs> _performCallAction(
    Session session,
    String uri,
    List<Object?> args,
    Map<String, Object?> kwArgs,
  ) async {
    try {
      final result = await session.call(uri, args: args, kwargs: kwArgs);
      final formattedArgs = prettyJson(result.args);
      final formattedKwargs = prettyJson(result.kwargs);
      return Logs(data: "Call result:\nargs:\n$formattedArgs\nkwargs:\n$formattedKwargs");
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
      final registration = await session.register(uri, (Invocation inv) {
        return Result(args: inv.args, kwargs: inv.kwargs);
      });
      registrations[uri] = registration;
      selectedMethod.value = "unregister";
      return Logs(data: "Registered procedure: $uri");
    } on Exception {
      rethrow;
    }
  }

  Future<Logs> _performUnregisterAction(Session session, String uri) async {
    final registration = registrations[uri];
    if (registration == null) {
      return Logs(error: "No registration found for URI: $uri");
    }
    try {
      await session.unregister(registration);
      registrations.remove(uri);
      selectedMethod.value = "register";
      return Logs(data: "Unregistered procedure: $uri");
    } on Exception catch (e) {
      return Logs(error: "Failed to unregister: $e");
    }
  }

  Future<Logs> _performSubscribeAction(
    Session session,
    String uri,
  ) async {
    try {
      await _subscription?.cancel();
      final subscription = await session.subscribe(uri, (event) {
        final formattedArgs = prettyJson(event.args);
        final formattedKwargs = prettyJson(event.kwargs);
        _addLog("Event received:\nargs:\n$formattedArgs\nkwargs:\n$formattedKwargs");
      });
      subscriptions[uri] = subscription;
      _subscription = subscription as StreamSubscription?;
      selectedMethod.value = "unsubscribe";
      return Logs(data: "Subscribed to topic: $uri");
    } on Exception {
      rethrow;
    }
  }

  Future<Logs> _performUnsubscribeAction(Session session, String uri) async {
    final subscription = subscriptions[uri];
    if (subscription == null) {
      return Logs(error: "No subscription found for URI: $uri");
    }
    try {
      await session.unsubscribe(subscription);
      subscriptions.remove(uri);
      if (identical(_subscription, subscription)) {
        _subscription = null;
      }
      selectedMethod.value = "subscribe";
      return Logs(data: "Unsubscribed from topic: $uri");
    } on Exception catch (e) {
      return Logs(error: "Failed to unsubscribe: $e");
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

  String prettyJson(Object? json) {
    return const JsonEncoder.withIndent("  ").convert(json);
  }

  @override
  void refresh([bool force = false]) {
    if (_isRefreshing && !force) {
      return;
    }
    _isRefreshing = true;
    try {
      update();
    } finally {
      _isRefreshing = false;
    }
  }
}

class Logs {
  Logs({this.data, this.error});

  final String? data;
  final String? error;
}
