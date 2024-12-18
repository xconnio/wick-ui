import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:wick_ui/app/data/models/profile_model.dart";
import "package:wick_ui/app/modules/action/action_controller.dart";
import "package:wick_ui/app/modules/profile/profile_controller.dart";
import "package:wick_ui/utils/action_button.dart";
import "package:wick_ui/utils/args_controller.dart";
import "package:wick_ui/utils/kwargs_controller.dart";
import "package:wick_ui/utils/responsive_scaffold.dart";

class ActionView extends StatelessWidget {
  ActionView({super.key});

  final ActionController actionController = Get.put(ActionController());
  final ProfileController profileController = Get.put(ProfileController());
  final ArgsController argsController = Get.put(ArgsController());
  final TextEditingController uriController = TextEditingController();
  final KwargsController kwargsController = Get.put(KwargsController());
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final List<String> wampMethods = [
    "Call",
    "Register",
    "Subscribe",
    "Publish",
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: "Actions",
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUriBar(),
            const SizedBox(height: 8),
            _buildLogsWindow(),
            const SizedBox(height: 8),
            Expanded(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  if (constraints.maxWidth >= 800) {
                    // Desktop/Web layout
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildArgsTab(),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildKwargsTab(),
                        ),
                      ],
                    );
                  } else {
                    // Mobile/Tablet layout
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildArgsTab(),
                        const SizedBox(height: 8),
                        _buildKwargsTab(),
                      ],
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUriBar() {
    final bool isMobile =
        !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: isMobile
              ? [
                  // URI Input Field (Mobile/Web layout)
                  TextFormField(
                    controller: uriController,
                    decoration: const InputDecoration(
                      labelText: "URI",
                      border: InputBorder.none,
                    ),
                    validator: (value) => value == null || value.isEmpty ? "URI cannot be empty." : null,
                  ),
                  const SizedBox(height: 8),
                  // Profile and WAMP Method Row
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Obx(() {
                          return DropdownButtonFormField<ProfileModel>(
                            isExpanded: true,
                            hint: const Text("Select Profile"),
                            value: actionController.selectedProfile.value,
                            onChanged: (ProfileModel? newValue) async {
                              await actionController.setSelectedProfile(newValue!);
                            },
                            validator: (value) => value == null ? "Please select a profile." : null,
                            items: profileController.profiles.map((ProfileModel profile) {
                              return DropdownMenuItem<ProfileModel>(
                                value: profile,
                                child: Text(profile.name),
                              );
                            }).toList(),
                          );
                        }),
                      ),
                      const SizedBox(width: 8),
                      // WAMP Method Dropdown and Button
                      Expanded(
                        flex: 2,
                        child: Obx(() {
                          return WampMethodButton(
                            selectedMethod: actionController.selectedWampMethod.value.isNotEmpty
                                ? actionController.selectedWampMethod.value
                                : "Call",
                            methods: wampMethods,
                            onMethodChanged: (String? newValue) {
                              actionController.selectedWampMethod.value = newValue!;
                            },
                            onMethodCalled: () async {
                              if (_formKey.currentState?.validate() ?? false) {
                                List<String> args =
                                    argsController.controllers.map((controller) => controller.text).toList();
                                Map<String, String> kwArgs = {
                                  for (final entry in kwargsController.tableData) entry.key: entry.value,
                                };

                                await actionController
                                    .performAction(
                                  actionController.selectedWampMethod.value.isNotEmpty
                                      ? actionController.selectedWampMethod.value
                                      : "Call",
                                  uriController.text,
                                  args,
                                  kwArgs,
                                )
                                    .then((_) async {
                                  if (_scrollController.hasClients) {
                                    await _scrollController.animateTo(
                                      _scrollController.position.maxScrollExtent,
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeOut,
                                    );
                                  }
                                });
                              }
                            },
                          );
                        }),
                      ),
                    ],
                  ),
                ]
              : [
                  // Desktop Layout (no mobile-specific behavior)
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Obx(() {
                          return DropdownButtonFormField<ProfileModel>(
                            isExpanded: true,
                            hint: const Text("Select Profile"),
                            value: actionController.selectedProfile.value,
                            onChanged: (ProfileModel? newValue) async {
                              await actionController.setSelectedProfile(newValue!);
                            },
                            validator: (value) => value == null ? "Please select a profile." : null,
                            items: profileController.profiles.map((ProfileModel profile) {
                              return DropdownMenuItem<ProfileModel>(
                                value: profile,
                                child: Text(profile.name),
                              );
                            }).toList(),
                          );
                        }),
                      ),
                      const SizedBox(width: 8),
                      // URI Input Field
                      Expanded(
                        flex: 4,
                        child: TextFormField(
                          controller: uriController,
                          decoration: const InputDecoration(
                            labelText: "URI",
                            border: InputBorder.none,
                          ),
                          validator: (value) => value == null || value.isEmpty ? "URI cannot be empty." : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // WAMP Method Dropdown and Button
                      Expanded(
                        flex: 2,
                        child: Obx(() {
                          return WampMethodButton(
                            selectedMethod: actionController.selectedWampMethod.value.isNotEmpty
                                ? actionController.selectedWampMethod.value
                                : "Call",
                            methods: wampMethods,
                            onMethodChanged: (String? newValue) {
                              actionController.selectedWampMethod.value = newValue!;
                            },
                            onMethodCalled: () async {
                              if (_formKey.currentState?.validate() ?? false) {
                                List<String> args =
                                    argsController.controllers.map((controller) => controller.text).toList();
                                Map<String, String> kwArgs = {
                                  for (final entry in kwargsController.tableData) entry.key: entry.value,
                                };

                                await actionController
                                    .performAction(
                                  actionController.selectedWampMethod.value.isNotEmpty
                                      ? actionController.selectedWampMethod.value
                                      : "Call",
                                  uriController.text,
                                  args,
                                  kwArgs,
                                )
                                    .then((_) async {
                                  if (_scrollController.hasClients) {
                                    await _scrollController.animateTo(
                                      _scrollController.position.maxScrollExtent,
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeOut,
                                    );
                                  }
                                });
                              }
                            },
                          );
                        }),
                      ),
                    ],
                  ),
                ],
        ),
      ),
    );
  }

  Widget _buildArgsTab() {
    return Obx(() {
      return SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Args"),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: argsController.addController,
                  ),
                ],
              ),
              for (int i = 0; i < argsController.controllers.length; i++)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: argsController.controllers[i],
                        decoration: InputDecoration(
                          labelText: "Args ${i + 1}",
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed:
                          argsController.controllers.length > 1 ? () => argsController.removeController(i) : null,
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildKwargsTab() {
    return Obx(() {
      return SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Kwargs"),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      kwargsController.addRow(const MapEntry("", ""));
                    },
                  ),
                ],
              ),
              for (int i = 0; i < kwargsController.tableData.length; i++)
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: kwargsController.tableData[i].key,
                        decoration: const InputDecoration(
                          labelText: "Key",
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          final updatedEntry = MapEntry(
                            value,
                            kwargsController.tableData[i].value,
                          );
                          kwargsController.updateRow(i, updatedEntry);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: kwargsController.tableData[i].value,
                        decoration: const InputDecoration(
                          labelText: "Value",
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          final updatedEntry = MapEntry(
                            value,
                            kwargsController.tableData[i].value,
                          );
                          kwargsController.updateRow(i, updatedEntry);
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: kwargsController.tableData.length > 1 ? () => kwargsController.removeRow(i) : null,
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildLogsWindow() {
    return Obx(() {
      final Orientation orientation = MediaQuery.of(Get.context!).orientation;
      final double screenHeight = MediaQuery.of(Get.context!).size.height;
      final double logsHeight = orientation == Orientation.portrait ? screenHeight * 0.25 : screenHeight * 0.4;

      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                "Logs",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: logsHeight,
              child: ListView(
                controller: _scrollController,
                children: [
                  Text(actionController.logsMessage.value),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty<ActionController>("actionController", actionController))
    ..add(DiagnosticsProperty<ProfileController>("profileController", profileController))
    ..add(DiagnosticsProperty<ArgsController>("argsController", argsController))
    ..add(DiagnosticsProperty<TextEditingController>("uriController", uriController))
    ..add(DiagnosticsProperty<KwargsController>("kwargsController", kwargsController))
    ..add(IterableProperty<String>("wampMethods", wampMethods));
  }
}
