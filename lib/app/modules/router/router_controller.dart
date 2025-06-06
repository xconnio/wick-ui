import "dart:developer";
import "dart:io";
import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:path/path.dart" as path;
import "package:path_provider/path_provider.dart";
import "package:wick_ui/app/data/models/authenticator/authenticator_config.dart";
import "package:wick_ui/app/data/models/router/realm_config.dart";
import "package:wick_ui/app/data/models/router/router_config_model.dart";
import "package:wick_ui/app/data/models/router/tranport_config.dart";
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
            final server = startRouter("localhost", transport.port, [realm.name]);
            activeRouters[realm.name] = server;
            log(
              "RouterController: Restored router '${realm.name}' on port ${transport.port}",
            );
          } on Exception catch (e) {
            runningRouters[realm.name] = false;
            log(
              "RouterController: Failed to restore router '${realm.name}': $e",
            );
          }
        }
      }
    }
  }

  Future<void> runRouter(RealmConfig realm) async {
    try {
      final config = routerConfigs.firstWhere((c) => c.realms.contains(realm));
      final transport = config.transports.first;
      if (runningRouters[realm.name] ?? false) {
        log("RouterController: Router '${realm.name}' already running");
        return;
      }
      final server = startRouter("localhost", transport.port, [realm.name]);
      activeRouters[realm.name] = server;
      runningRouters[realm.name] = true;
      await saveRouterState();
      log(
        "RouterController: Started router '${realm.name}' on port ${transport.port}",
      );
    } on Exception catch (e) {
      log("RouterController: Failed to start router '${realm.name}': $e");
    }
  }

  Future<void> stopRouter(String realmName) async {
    try {
      final server = activeRouters[realmName];
      if (server != null) {
        await server.close();
        activeRouters.remove(realmName);
        runningRouters[realmName] = false;
        await saveRouterState();
        log("RouterController: Stopped router '$realmName'");
      }
    } on Exception catch (e) {
      log("RouterController: Failed to stop router '$realmName': $e");
    }
  }

  Future<void> stopAllRouters() async {
    log("RouterController: Stopping all routers");
    try {
      for (final server in activeRouters.values) {
        await server.close();
        log("RouterController: Closed a server");
      }
      activeRouters.clear();
      runningRouters.updateAll((key, value) => false);
      await clearRouterState();
      log("RouterController: All routers stopped and state cleared");
    } on Exception catch (e) {
      log("RouterController: Failed to stop all routers: $e");
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

  Future<void> saveRouterConfig(RouterConfigModel config) async {
    try {
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
      final directory = await getApplicationDocumentsDirectory();
      final file = File("${directory.path}/router_config_$index.yaml");

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
    final formKey = GlobalKey<FormState>();
    final config = configToEdit ?? (index != null ? routerConfigs[index] : null);

    final TextEditingController versionController = TextEditingController(
      text: config?.version ?? "1",
    );
    final TextEditingController realmController = TextEditingController(
      text: config != null && config.realms.isNotEmpty ? config.realms.first.name : "",
    );
    final TextEditingController transportPortController = TextEditingController(
      text: config != null && config.transports.isNotEmpty ? config.transports.first.port.toString() : "",
    );

    final RxMap<String, bool> selectedSerializers = {
      "json": config != null && config.transports.isNotEmpty && config.transports.first.serializers.contains("json"),
      "msgpack":
          config != null && config.transports.isNotEmpty && config.transports.first.serializers.contains("msgpack"),
      "cbor": config != null && config.transports.isNotEmpty && config.transports.first.serializers.contains("cbor"),
    }.obs;

    await Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          bool isDesktop = MediaQuery.of(context).size.width > 600;
          double dialogWidth =
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
                        _buildTextField(
                          controller: versionController,
                          labelText: "Version",
                          context: context,
                          validator: (value) => value!.isEmpty ? "Please enter a version" : null,
                        ),
                        SizedBox(height: _responsiveSpacing(context)),
                        _buildTextField(
                          controller: realmController,
                          labelText: "Realm Name",
                          context: context,
                          validator: (value) => value!.isEmpty ? "Please enter a realm name" : null,
                        ),
                        SizedBox(height: _responsiveSpacing(context)),
                        _buildResponsiveFields(
                          isDesktop: isDesktop,
                          context: context,
                          fieldOne: _buildTextField(
                            controller: transportPortController,
                            labelText: "Transport Port",
                            context: context,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value!.isEmpty) {
                                return "Please enter a transport port";
                              }
                              final port = int.tryParse(value);
                              if (port == null || port < 0 || port > 65535) {
                                return "Port must be between 0 and 65535";
                              }
                              return null;
                            },
                          ),
                          fieldTwo: Obx(
                            () => Column(
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
                                      setState(() {
                                        selectedSerializers[entry.key] = value ?? false;
                                      });
                                    },
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                  );
                                }),
                              ],
                            ),
                          ),
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
                  if (formKey.currentState!.validate()) {
                    final realmConfig = RealmConfig(name: realmController.text);
                    final transportConfig = TransportConfig(
                      port: int.parse(transportPortController.text),
                      serializers:
                          selectedSerializers.entries.where((entry) => entry.value).map((entry) => entry.key).toList(),
                    );

                    final newConfig = RouterConfigModel(
                      version: versionController.text,
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

  Widget _buildResponsiveFields({
    required bool isDesktop,
    required BuildContext context,
    required Widget fieldOne,
    required Widget fieldTwo,
  }) {
    if (isDesktop) {
      return Row(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: _responsiveSpacing(context) / 2),
              child: fieldOne,
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: _responsiveSpacing(context) / 2),
              child: fieldTwo,
            ),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          fieldOne,
          SizedBox(height: _responsiveSpacing(context)),
          fieldTwo,
        ],
      );
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required BuildContext context,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
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
