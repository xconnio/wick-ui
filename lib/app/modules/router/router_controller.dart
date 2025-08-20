import "dart:async";
import "dart:developer";
import "dart:io";
import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:path/path.dart" as path;
import "package:path_provider/path_provider.dart";
import "package:wick_ui/app/data/models/authenticator/authenticator_config.dart";
import "package:wick_ui/app/data/models/router/realm_config.dart";
import "package:wick_ui/app/data/models/router/router_config_model.dart";
import "package:wick_ui/app/data/models/router/transport_config.dart";
import "package:wick_ui/utils/state_manager.dart";
import "package:wick_ui/wamp_util.dart";
import "package:xconn/xconn.dart";
import "package:yaml/yaml.dart";
import "package:yaml_writer/yaml_writer.dart";

class RouterController extends GetxController with StateManager {
  RxList<RouterConfigModel> routerConfigs = <RouterConfigModel>[].obs;
  final Map<String, Server> activeRouters = {};

  @override
  Future<void> onInit() async {
    super.onInit();
    log("RouterController: onInit called");
    await initializeState();
    await loadRouterConfigs();
    await restoreRunningRouters();
  }

  Future<void> loadRouterConfigs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = await directory.list().where((file) => file is File && file.path.endsWith(".yaml")).toList();

      routerConfigs.clear();

      for (final file in files) {
        if (file is File && path.basename(file.path).startsWith("router_config")) {
          final yamlString = await file.readAsString();
          final yamlMap = loadYaml(yamlString);
          final configMap = yamlToMap(yamlMap);

          final config = RouterConfigModel.fromJson(configMap);
          routerConfigs.add(config);

          for (final realm in config.realms) {
            if (!runningRouters.containsKey(realm.name)) {
              runningRouters[realm.name] = false;
            }
          }
        }
      }
      log("RouterController: Loaded ${routerConfigs.length} router configs");
    } on Exception catch (e) {
      log("RouterController: Load failed: $e");
    }
  }

  Future<void> restoreRunningRouters() async {
    log("RouterController: Restoring running routers");
    for (final config in routerConfigs) {
      for (final realm in config.realms) {
        if ((runningRouters[realm.name] ?? false) && activeRouters[realm.name] == null) {
          try {
            final transport = config.transports.first;
            if (await isPortAvailable(transport.port)) {
              final server = startRouter("localhost", transport.port, [realm.name]);
              activeRouters[realm.name] = server;
              log("RouterController: Restored router '${realm.name}' on port ${transport.port}");
            } else {
              runningRouters[realm.name] = false;
              log("RouterController: Failed to restore router '${realm.name}' - port in use");
            }
          } on Exception catch (e) {
            runningRouters[realm.name] = false;
            log("RouterController: Failed to restore router '${realm.name}': $e");
          }
        }
      }
    }
    await saveRouterState();
  }

  Future<bool> isPortAvailable(int port, {String host = "localhost"}) async {
    try {
      final socket = await ServerSocket.bind(host, port);
      await socket.close();
      return true;
    } on Exception catch (_) {
      return false;
    }
  }

  Future<void> runRouter(RealmConfig realm) async {
    log("RouterController: Attempting to start router '${realm.name}'");
    try {
      final config = routerConfigs.firstWhere(
        (c) => c.realms.contains(realm),
        orElse: () => RouterConfigModel(
          version: "1",
          name: "Unnamed Router",
          realms: [realm],
          transports: [
            TransportConfig(port: 8080, serializers: ["json"]),
          ],
          authenticators: AuthenticatorConfig(
            cryptosign: [],
            wampcra: [],
            ticket: [],
            anonymous: [],
          ),
        ),
      );

      final transport = config.transports.first;
      if (runningRouters[realm.name] ?? false) {
        log("RouterController: Router '${realm.name}' already running");
        return;
      }

      log("RouterController: Starting router '${realm.name}' on port ${transport.port}");

      if (!await isPortAvailable(transport.port)) {
        log("RouterController: Port ${transport.port} already in use.");
        Get.snackbar(
          "Error",
          "Port ${transport.port} already in use.",
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final server = startRouter("localhost", transport.port, [realm.name]);
      activeRouters[realm.name] = server;
      runningRouters[realm.name] = true;

      await saveRouterState();
      routerConfigs.refresh();

      log("RouterController: Successfully started router '${realm.name}'");
    } on Exception catch (e, stackTrace) {
      log("RouterController: Failed to start router '${realm.name}': $e\n$stackTrace");
      runningRouters[realm.name] = false;
      activeRouters.remove(realm.name);
      await saveRouterState();
      routerConfigs.refresh();
    }
  }

  Future<void> stopRouter(String realmName) async {
    log("RouterController: Attempting to stop router '$realmName'");
    try {
      final server = activeRouters[realmName];
      if (server != null) {
        log("RouterController: Closing server for '$realmName'");
        try {
          await server.close();
          log("RouterController: Server closed for '$realmName'");
        } on Exception catch (e) {
          log("RouterController: Error closing server for '$realmName': $e");
        }
        activeRouters.remove(realmName);
      }

      runningRouters[realmName] = false;

      await saveRouterState();
      routerConfigs.refresh();

      log("RouterController: Successfully stopped router '$realmName'");
    } on Exception catch (e, stackTrace) {
      log("RouterController: Failed to stop router '$realmName': $e\n$stackTrace");

      runningRouters[realmName] = false;
      activeRouters.remove(realmName);
      await saveRouterState();
      routerConfigs.refresh();
    }
  }

  Future<void> stopAllRouters() async {
    log("RouterController: Stopping all routers");
    try {
      for (final entry in activeRouters.entries) {
        try {
          log("RouterController: Closing server for '${entry.key}'");
          await entry.value.close();
          log("RouterController: Server closed for '${entry.key}'");
        } on Exception catch (e) {
          log("RouterController: Error closing server for '${entry.key}': $e");
        }
      }
      activeRouters.clear();

      runningRouters.updateAll((key, value) => false);

      await clearRouterState();
      routerConfigs.refresh();

      log("RouterController: All routers stopped and state cleared");
    } on Exception catch (e) {
      log("RouterController: Failed to stop all routers: $e");

      activeRouters.clear();
      runningRouters.updateAll((key, value) => false);
      await clearRouterState();
      routerConfigs.refresh();
    }
  }

  Map<String, dynamic> yamlToMap(YamlMap yaml) {
    final Map<String, dynamic> map = {};
    yaml.forEach((key, value) {
      if (value is YamlMap) {
        map[key.toString()] = yamlToMap(value);
      } else if (value is List) {
        map[key.toString()] = yamlListToList(value);
      } else {
        map[key.toString()] = value;
      }
    });
    return map;
  }

  List yamlListToList(List list) {
    return list.map((item) {
      if (item is YamlMap) {
        return yamlToMap(item);
      } else if (item is List) {
        return yamlListToList(item);
      } else {
        return item;
      }
    }).toList();
  }

  Future<bool> isRouterNameUnique(
    String routerName, {
    int? excludeIndex,
  }) async {
    for (int i = 0; i < routerConfigs.length; i++) {
      if (excludeIndex != null && i == excludeIndex) {
        continue;
      }
      final config = routerConfigs[i];
      if (config.name == routerName) {
        return false;
      }
    }
    return true;
  }

  Future<void> saveRouterConfig(RouterConfigModel config) async {
    try {
      if (!await isRouterNameUnique(config.name)) {
        log("RouterController: Cannot save config, realm name '${config.name}' already exists");
        return;
      }

      final directory = await getApplicationDocumentsDirectory();
      final file = File("${directory.path}/router_config_${routerConfigs.length}.yaml");

      final yaml = YamlWriter().write(config.toJson());
      await file.writeAsString(yaml);

      routerConfigs
        ..add(config)
        ..refresh();
      log("RouterController: Saved router config: ${file.path}");
    } on Exception catch (e) {
      log("RouterController: Save failed: $e");
    }
  }

  Future<void> updateRouterConfig(int index, RouterConfigModel config) async {
    try {
      if (!await isRouterNameUnique(config.name, excludeIndex: index)) {
        log("RouterController: Cannot update config, realm name '${config.name}' already exists");
        return;
      }

      final directory = await getApplicationDocumentsDirectory();
      final file = File("${directory.path}/router W_config_$index.yaml");

      final yaml = YamlWriter().write(config.toJson());
      await file.writeAsString(yaml);

      routerConfigs[index] = config;
      routerConfigs.refresh();
      log("RouterController: Updated router config at index $index");
    } on Exception catch (e) {
      log("RouterController: Update failed: $e");
    }
  }

  Future<void> deleteRouterConfig(int index) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File("${directory.path}/router_config_$index.yaml");

      await file.delete();

      routerConfigs
        ..removeAt(index)
        ..refresh();
      log("RouterController: Deleted router config at index $index");
    } on Exception catch (e) {
      log("RouterController: Delete failed: $e");
    }
  }

  Future<void> createRouterConfig({
    RouterConfigModel? configToEdit,
    int? index,
  }) async {
    log("RouterController: createRouterConfig called with configToEdit=$configToEdit, index=$index");
    final formKey = GlobalKey<FormState>();
    final config =
        configToEdit ?? (index != null && index >= 0 && index < routerConfigs.length ? routerConfigs[index] : null);

    final versionController = TextEditingController(
      text: config?.version ?? "1",
    );
    final nameController = TextEditingController(
      text: config?.name ?? "",
    );
    final realmController = TextEditingController(
      text: config?.realms.isNotEmpty ?? false ? config!.realms.first.name : "",
    );
    final transportPortController = TextEditingController(
      text: config?.transports.isNotEmpty ?? false ? config!.transports.first.port.toString() : "8080",
    );
    final RxMap<String, bool> selectedSerializers = {
      "json": config?.transports.firstOrNull?.serializers.contains("json") ?? true,
      "msgpack": config?.transports.firstOrNull?.serializers.contains("msgpack") ?? false,
      "cbor": config?.transports.firstOrNull?.serializers.contains("cbor") ?? false,
    }.obs;

    final RxString nameError = RxString("");

    await Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          final isDesktop = MediaQuery.of(context).size.width > 600;
          final dialogWidth =
              isDesktop ? MediaQuery.of(context).size.width * 0.6 : MediaQuery.of(context).size.width * 0.9;

          return AlertDialog(
            title: Text(
              configToEdit == null && index == null ? "Create New Router" : "Edit Router Config",
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: SizedBox(
                width: dialogWidth,
                height: MediaQuery.of(context).size.height * 0.6,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Obx(
                          () => _buildTextField(
                            controller: nameController,
                            labelText: "Name",
                            context: context,
                            errorText: nameError.value.isNotEmpty ? nameError.value : null,
                            validator: (value) {
                              if (value!.isEmpty) {
                                return "Please enter a router name";
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(height: _responsiveSpacing(context)),
                        _buildTextField(
                          controller: realmController,
                          labelText: "Realm",
                          context: context,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return "Please enter a router realm";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: _responsiveSpacing(context)),
                        _buildTextField(
                          controller: transportPortController,
                          labelText: "Port",
                          context: context,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return "Please enter a router port";
                            }
                            final port = int.tryParse(value);
                            if (port == null || port < 0 || port > 65535) {
                              return "Port must be between 0 and 65535";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: _responsiveSpacing(context)),
                        FormField<List<String>>(
                          initialValue: selectedSerializers.entries
                              .where((entry) => entry.value)
                              .map((entry) => entry.key)
                              .toList(),
                          validator: (selected) {
                            if (selected == null || selected.isEmpty) {
                              return "Please select at least one serializer";
                            }
                            return null;
                          },
                          builder: (field) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Serializers",
                                  style: TextStyle(fontSize: 16),
                                ),
                                ...selectedSerializers.entries.map((entry) {
                                  return CheckboxListTile(
                                    title: Text(entry.key),
                                    value: entry.value,
                                    onChanged: (value) {
                                      selectedSerializers[entry.key] = value ?? false;
                                      field.didChange(
                                        selectedSerializers.entries.where((e) => e.value).map((e) => e.key).toList(),
                                      );
                                    },
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                  );
                                }),
                                if (field.hasError)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 16, top: 4),
                                    child: Text(
                                      field.errorText!,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.error,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: Get.back,
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  nameError.value = "";

                  if (formKey.currentState!.validate()) {
                    final newRouterName = nameController.text;

                    if (index == null && !await isRouterNameUnique(newRouterName)) {
                      nameError.value = 'Router name "$newRouterName" is already in use';
                      return;
                    }

                    final selected =
                        selectedSerializers.entries.where((entry) => entry.value).map((entry) => entry.key).toList();

                    final realmConfig = RealmConfig(name: realmController.text);
                    final transportConfig = TransportConfig(
                      port: int.parse(transportPortController.text),
                      serializers: selected,
                    );

                    final newConfig = RouterConfigModel(
                      version: versionController.text,
                      name: nameController.text,
                      realms: [realmConfig],
                      transports: [transportConfig],
                      authenticators: AuthenticatorConfig(
                        cryptosign: [],
                        wampcra: [],
                        ticket: [],
                        anonymous: [],
                      ),
                    );

                    if (index == null) {
                      await saveRouterConfig(newConfig);
                    } else {
                      await updateRouterConfig(index, newConfig);
                    }

                    Get.back();
                  }
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      ),
      barrierDismissible: false,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required BuildContext context,
    String? errorText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        errorText: errorText,
        isDense: true,
        contentPadding: _responsivePadding(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  EdgeInsets _responsivePadding(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return EdgeInsets.symmetric(
      vertical: screenWidth > 600 ? 12.0 : 8.0,
      horizontal: screenWidth > 600 ? 16.0 : 12.0,
    );
  }

  double _responsiveSpacing(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return screenWidth > 600 ? 16.0 : 12.0;
  }
}
