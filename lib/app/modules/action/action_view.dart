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
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUriBar() {
    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
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
                    // Trigger validation
                    if (_formKey.currentState?.validate() ?? false) {
                      List<String> args = argsController.controllers.map((controller) => controller.text).toList();
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
                        // Scroll to the bottom after the action is performed
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
      ),
    );
  }

  Widget _buildArgsTab() {
    return Obx(() {
      return Container(
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
                  // SizedBox(height: 8,);
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: argsController.controllers.length > 1 ? () => argsController.removeController(i) : null,
                  ),
                ],
              ),
          ],
        ),
      );
    });
  }

  Widget _buildKwargsTab() {
    return Obx(() {
      return Container(
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
                    flex: 2,
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: "Key ${i + 1}",
                        border: const OutlineInputBorder(),
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
                    flex: 3,
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: "Value ${i + 1}",
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        final updatedEntry = MapEntry(
                          kwargsController.tableData[i].key,
                          value,
                        );
                        kwargsController.updateRow(i, updatedEntry);
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: kwargsController.tableData.length > 1
                        ? () => kwargsController.removeRow(i)
                        : null, // Disable if only one row is left
                  ),
                ],
              ),
          ],
        ),
      );
    });
  }

  Widget _buildLogsWindow() {
    return Obx(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (_scrollController.hasClients) {
          await _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

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
            Container(
              padding: const EdgeInsets.all(8),
              height: 150,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Text(actionController.logsMessage.value),
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
    properties
      ..add(
        DiagnosticsProperty<ActionController>(
          "actionController",
          actionController,
        ),
      )
      ..add(IterableProperty<String>("wampMethods", wampMethods))
      ..add(
        DiagnosticsProperty<TextEditingController>(
          "uriController",
          uriController,
        ),
      )
      ..add(
        DiagnosticsProperty<ArgsController>("argsController", argsController),
      )
      ..add(
        DiagnosticsProperty<ProfileController>(
          "profileController",
          profileController,
        ),
      )
      ..add(
        DiagnosticsProperty<KwargsController>(
          "kwargsController",
          kwargsController,
        ),
      );
  }
}
