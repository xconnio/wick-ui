import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:wick_ui/app/data/models/client_model.dart";
import "package:wick_ui/app/modules/action/action_controller.dart";
import "package:wick_ui/app/modules/client/client_controller.dart";
import "package:wick_ui/utils/args_controller.dart";
import "package:wick_ui/utils/kwargs_controller.dart";
import "package:wick_ui/utils/responsive_scaffold.dart";
import "package:wick_ui/utils/status_indicator.dart";
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
    final double screenHeight = MediaQuery.of(context).size.height;

    return ResponsiveScaffold(
      title: "Actions",
      body: TabContainerWidget(
        buildScreen: (context, tabKey) => _buildScreen(context, tabKey, screenHeight),
      ),
    );
  }

  Widget _buildScreen(BuildContext context, int tabKey, double screenHeight) {
    if (!Get.isRegistered<ArgsController>(tag: "args_$tabKey")) {
      Get.put(ArgsController(), tag: "args_$tabKey");
    }
    if (!Get.isRegistered<KwargsController>(tag: "kwargs_$tabKey")) {
      Get.put(KwargsController(), tag: "kwargs_$tabKey");
    }
    if (!Get.isRegistered<ActionController>(tag: "action_$tabKey")) {
      Get.put(ActionController(), tag: "action_$tabKey");
    }

    final ActionController actionController = Get.find<ActionController>(tag: "action_$tabKey");
    final ClientController clientController = Get.find<ClientController>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildUriBar(tabKey, actionController, clientController),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          SliverToBoxAdapter(child: _buildLogsWindow(tabKey, screenHeight)),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          SliverToBoxAdapter(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: screenHeight * 0.4,
              ),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  if (constraints.maxWidth >= 800) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildArgsTab(tabKey)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildKwargsTab(tabKey)),
                      ],
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildArgsTab(tabKey),
                        const SizedBox(height: 8),
                        _buildKwargsTab(tabKey),
                      ],
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUriBar(
    int tabKey,
    ActionController actionController,
      ClientController clientController,
  ) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final bool isMobile =
        !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

    return Form(
      key: formKey,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade600),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: isMobile
              ? [
                  TextFormField(
                    controller: actionController.uriController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "URI",
                      labelStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                    ),
                    validator: (value) => value == null || value.isEmpty ? "URI cannot be empty." : null,
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildDropdown(tabKey, actionController, clientController),
                      ),
                      Expanded(
                        flex: 2,
                        child: _buildWampMethodButton(tabKey, formKey),
                      ),
                    ],
                  ),
                ]
              : [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildDropdown(tabKey, actionController, clientController),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 4,
                        child: TextFormField(
                          controller: actionController.uriController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: "URI",
                            labelStyle: TextStyle(color: Colors.grey),
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

  Widget _buildDropdown(int tabKey, ActionController actionController, ClientController clientController) {
    return Obx(() {
      return DropdownButtonFormField<ClientModel>(
        isExpanded: true,
        hint: const Text("Select Client", style: TextStyle(color: Colors.grey)),
        value: actionController.ClientClient.value,
        style: const TextStyle(color: Colors.white),
        dropdownColor: Colors.grey.shade800,
        onChanged: (ClientModel? newValue) async {
          await actionController.setSelectedClient(newValue!);
        },
        validator: (value) => value == null ? "Please select a client." : null,
        items: clientController.clients.map((ClientModel client) {
          return DropdownMenuItem<ClientModel>(
            value: client,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    client.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                StatusIndicator(
                  isActive: clientController.clientSessions[client.name] ?? false,
                ),
              ],
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildWampMethodButton(int tabKey, GlobalKey<FormState> formKey) {
    final ActionController actionController = Get.find<ActionController>(tag: "action_$tabKey");
    final ArgsController argsController = Get.find<ArgsController>(tag: "args_$tabKey");
    final KwargsController kwargsController = Get.find<KwargsController>(tag: "kwargs_$tabKey");

    return Obx(() {
      return DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade600),
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
                      actionController.uriController.text,
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
                          color: Colors.white,
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
                    child: Text(method, style: const TextStyle(color: Colors.white)),
                  );
                }).toList();
              },
              color: Colors.grey.shade800,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: const BoxDecoration(
                  border: Border(left: BorderSide(color: Colors.grey)),
                ),
                child: const Icon(Icons.arrow_drop_down, size: 24, color: Colors.white),
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
      return Container(
        height: 200,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade600),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Args", style: TextStyle(color: Colors.white)),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: argsController.addController,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ListView.separated(
                  itemCount: argsController.controllers.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    return Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: argsController.controllers[i],
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: "Args ${i + 1}",
                              labelStyle: const TextStyle(color: Colors.grey),
                              border: const OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey.shade600),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.white),
                          onPressed:
                              argsController.controllers.length > 1 ? () => argsController.removeController(i) : null,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildKwargsTab(int tabKey) {
    final KwargsController kwargsController = Get.find<KwargsController>(tag: "kwargs_$tabKey");

    return Obx(() {
      return Container(
        height: 200, // Fixed height to match screenshot
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade600),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Kwargs", style: TextStyle(color: Colors.white)),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: () {
                      kwargsController.addRow(const MapEntry("", ""));
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ListView.separated(
                  itemCount: kwargsController.tableData.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    return Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: kwargsController.tableData[i].key,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: "Key",
                              labelStyle: const TextStyle(color: Colors.grey),
                              border: const OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey.shade600),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
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
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: "Value",
                              labelStyle: const TextStyle(color: Colors.grey),
                              border: const OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey.shade600),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
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
                          icon: const Icon(Icons.delete, color: Colors.white),
                          onPressed: kwargsController.tableData.length > 1 ? () => kwargsController.removeRow(i) : null,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildLogsWindow(int tabKey, double screenHeight) {
    if (!Get.isRegistered<ScrollController>(tag: "logs_$tabKey")) {
      Get.put(ScrollController(), tag: "logs_$tabKey");
    }
    final ScrollController scrollController = Get.find<ScrollController>(tag: "logs_$tabKey");
    final ActionController actionController = Get.find<ActionController>(tag: "action_$tabKey");

    return Obx(() {
      final Orientation orientation = MediaQuery.of(Get.context!).orientation;
      final double logsHeight = orientation == Orientation.portrait
          ? (screenHeight <= 600 ? screenHeight * 0.5 : screenHeight * 0.1)
          : screenHeight * 0.2;
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade600),
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
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            SizedBox(
              height: logsHeight,
              child: ListView(
                controller: scrollController,
                children: [
                  Text(
                    actionController.logsMessage.value,
                    style: const TextStyle(color: Colors.white),
                  ),
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
