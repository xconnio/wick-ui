import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:wick_ui/app/data/models/profile_model.dart";
import "package:wick_ui/app/modules/action/action_controller.dart";
import "package:wick_ui/app/modules/profile/profile_controller.dart";
import "package:wick_ui/utils/args_controller.dart";
import "package:wick_ui/utils/kwargs_controller.dart";
import "package:wick_ui/utils/responsive_scaffold.dart";
import "package:wick_ui/utils/tab_container_state.dart";

class ActionView extends StatelessWidget {
  ActionView({super.key});

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
      body: TabContainerWidget(
        buildScreen: _buildScreen,
      ),
    );
  }

  Widget _buildScreen(BuildContext context, int tabKey) {
    Get
      ..put(ArgsController(), tag: "args_$tabKey")
      ..put(KwargsController(), tag: "kwargs_$tabKey");
    final ActionController actionController = Get.put(ActionController(), tag: "action_$tabKey");
    final ProfileController profileController = Get.put(ProfileController(), tag: "profile_$tabKey");

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUriBar(tabKey, actionController, profileController),
          const SizedBox(height: 4),
          _buildLogsWindow(tabKey),
          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                if (constraints.maxWidth >= 800) {
                  // Desktop/Web layout
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildArgsTab(tabKey),
                      ),
                      Expanded(
                        child: _buildKwargsTab(tabKey),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildArgsTab(tabKey)),
                      Expanded(child: _buildKwargsTab(tabKey)),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUriBar(
    int tabKey,
    ActionController actionController,
    ProfileController profileController,
  ) {
    final TextEditingController uriController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final bool isMobile =
        !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

    return Form(
      key: formKey,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: isMobile
              ? [
                  TextFormField(
                    controller: uriController,
                    decoration: const InputDecoration(
                      labelText: "URI",
                      border: InputBorder.none,
                    ),
                    validator: (value) => value == null || value.isEmpty ? "URI cannot be empty." : null,
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildDropdown(
                          tabKey,
                          actionController,
                          profileController,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: _buildWampMethodButton(
                          tabKey,
                          formKey,
                        ),
                      ),
                    ],
                  ),
                ]
              : [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildDropdown(
                          tabKey,
                          actionController,
                          profileController,
                        ),
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
                      Expanded(
                        flex: 2,
                        child: _buildWampMethodButton(tabKey, formKey),
                      ),
                    ],
                  ),
                ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
    int tabKey,
    ActionController actionController,
    ProfileController profileController,
  ) {
    return Obx(() {
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
    });
  }

  Widget _buildWampMethodButton(int tabKey, GlobalKey<FormState> formKey) {
    final ActionController actionController = Get.find<ActionController>(tag: "action_$tabKey");
    final ArgsController argsController = Get.find<ArgsController>(tag: "args_$tabKey");
    final KwargsController kwargsController = Get.find<KwargsController>(tag: "kwargs_$tabKey");
    final TextEditingController uriController = TextEditingController();

    return Obx(() {
      return DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  if (formKey.currentState?.validate() ?? false) {
                    List<String> args = argsController.controllers.map((c) => c.text).toList();
                    Map<String, String> kwArgs = {
                      for (final entry in kwargsController.tableData) entry.key: entry.value,
                    };

                    await actionController.performAction(
                      actionController.selectedWampMethod.value.isNotEmpty
                          ? actionController.selectedWampMethod.value
                          : wampMethods.first,
                      uriController.text,
                      args,
                      kwArgs,
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        actionController.selectedWampMethod.value.isNotEmpty
                            ? actionController.selectedWampMethod.value
                            : wampMethods.first,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            PopupMenuButton<String>(
              onSelected: (String newValue) {
                actionController.selectedWampMethod.value = newValue;
              },
              itemBuilder: (context) {
                return wampMethods.map((method) {
                  return PopupMenuItem<String>(
                    value: method,
                    child: Text(method),
                  );
                }).toList();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: const BoxDecoration(
                  border: Border(left: BorderSide(color: Colors.grey)),
                ),
                child: const Icon(Icons.arrow_drop_down, size: 24),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildArgsTab(int tabKey) {
    final ArgsController argsController = Get.find<ArgsController>(tag: "args_$tabKey");

    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Args"),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: argsController.addController,
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: List.generate(argsController.controllers.length, (i) {
                    return Column(
                      children: [
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
                              onPressed: argsController.controllers.length > 1
                                  ? () => argsController.removeController(i)
                                  : null,
                            ),
                          ],
                        ),
                        if (i != argsController.controllers.length - 1) const SizedBox(height: 12),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildKwargsTab(int tabKey) {
    final KwargsController kwargsController = Get.find<KwargsController>(tag: "kwargs_$tabKey");

    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
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
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(kwargsController.tableData.length, (i) {
                    return Column(
                      children: [
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
                                    kwargsController.tableData[i].key,
                                    value,
                                  );
                                  kwargsController.updateRow(i, updatedEntry);
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed:
                                  kwargsController.tableData.length > 1 ? () => kwargsController.removeRow(i) : null,
                            ),
                          ],
                        ),
                        if (i != kwargsController.tableData.length - 1) const SizedBox(height: 12),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildLogsWindow(int tabKey) {
    final ScrollController scrollController = Get.put(ScrollController(), tag: "logs_$tabKey");
    final ActionController actionController = Get.find<ActionController>(tag: "action_$tabKey");

    return Obx(() {
      final Orientation orientation = MediaQuery.of(Get.context!).orientation;
      final double screenHeight = MediaQuery.of(Get.context!).size.height;

      final double logsHeight = orientation == Orientation.portrait
          ? (screenHeight <= 600 ? screenHeight * 0.5 : screenHeight * 0.1)
          : screenHeight * 0.4;
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
              padding: EdgeInsets.all(4),
              child: Text(
                "Logs",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: logsHeight,
              child: ListView(
                controller: scrollController,
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
    properties.add(IterableProperty<String>("wampMethods", wampMethods));
  }
}
