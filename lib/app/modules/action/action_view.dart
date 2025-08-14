import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:wick_ui/app/data/models/client_model.dart";
import "package:wick_ui/app/modules/action/action_controller.dart";
import "package:wick_ui/app/modules/action/action_params_controller.dart";
import "package:wick_ui/app/modules/client/client_controller.dart";
import "package:wick_ui/config/theme/my_theme.dart";
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
    return Theme(
      data: MyTheme.dark(),
      child: ResponsiveScaffold(
        body: TabContainerWidget(
          buildScreen: _buildScreen,
        ),
      ),
    );
  }

  Widget _buildScreen(BuildContext context, int tabKey) {
    final actionTag = "action_$tabKey";
    final paramsTag = "params_$tabKey";

    if (!Get.isRegistered<ActionController>(tag: actionTag)) {
      Get.lazyPut<ActionController>(
        ActionController.new,
        tag: actionTag,
        fenix: true,
      );
    }

    if (!Get.isRegistered<ActionParamsController>(tag: paramsTag)) {
      Get.lazyPut<ActionParamsController>(
        ActionParamsController.new,
        tag: paramsTag,
        fenix: true,
      );
    }

    final actionController = Get.find<ActionController>(tag: actionTag);
    final clientController = Get.find<ClientController>();

    return Padding(
      padding: EdgeInsets.zero,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildUriBar(context, tabKey, actionController, clientController)),
          const SliverToBoxAdapter(child: SizedBox(height: 6)),
          SliverToBoxAdapter(child: _buildParamsSection(tabKey, actionController)),
          const SliverToBoxAdapter(child: SizedBox(height: 6)),
          SliverToBoxAdapter(child: _buildLogsWindow(tabKey, actionController)),
        ],
      ),
    );
  }

  // Widget _buildErrorWidget(ActionController controller) {
  //   return Obx(() {
  //     if (controller.errorMessage.value.isEmpty) {
  //       return const SizedBox.shrink();
  //     }
  //     return Container(
  //       padding: const EdgeInsets.all(12),
  //       decoration: BoxDecoration(
  //         color: Colors.red.shade900.withAlpha((0.3 * 255).round()),
  //         borderRadius: BorderRadius.circular(8),
  //         border: Border.all(color: Colors.redAccent),
  //       ),
  //       child: Row(
  //         children: [
  //           const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
  //           const SizedBox(width: 8),
  //           Expanded(child: Text(controller.errorMessage.value)),
  //         ],
  //       ),
  //     );
  //   });
  // }

  Widget _buildUriBar(
    BuildContext context,
    int tabKey,
    ActionController actionController,
    ClientController clientController,
  ) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    final bool isMobileApp =
        !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobileWeb = kIsWeb && constraints.maxWidth < 600;
        final bool isStackedLayout = isMobileApp || isMobileWeb;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade800),
          ),
          child: Form(
            key: formKey,
            child: Column(
              children: isStackedLayout
                  ? [
                      TextFormField(
                        controller: actionController.uriController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Procedure",
                          hintText: "Enter Procedure URI",
                          prefixIcon: Icon(Icons.link, size: 20),
                        ),
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.done,
                        validator: (value) => value == null || value.isEmpty ? "URI cannot be empty." : null,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildDropdown(tabKey, actionController, clientController),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: _buildWampMethodButton(tabKey, actionController),
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
                                labelText: "Procedure",
                                hintText: "Enter Procedure URI",
                                prefixIcon: Icon(Icons.link, size: 20),
                              ),
                              keyboardType: TextInputType.text,
                              textInputAction: TextInputAction.done,
                              validator: (value) => value == null || value.isEmpty ? "URI cannot be empty." : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: _buildWampMethodButton(tabKey, actionController),
                          ),
                        ],
                      ),
                    ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDropdown(int tabKey, ActionController actionController, ClientController clientController) {
    const createClientValue = "__create_client__";

    return Obx(() {
      return DropdownButtonFormField<dynamic>(
        isExpanded: true,
        hint: const Text("Select a client", style: TextStyle(color: Colors.grey)),
        value: actionController.selectedClient.value,
        style: const TextStyle(color: Colors.white),
        dropdownColor: Colors.grey.shade900,
        icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.person_outline, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onChanged: (value) async {
          if (value == null) {
            return;
          }

          if (value == createClientValue) {
            final previousValue = actionController.selectedClient.value;

            final int oldCount = clientController.clients.length;

            actionController.selectedClient.value = null;

            await clientController.createClient();

            final int newCount = clientController.clients.length;

            if (newCount > oldCount) {
              final newClient = clientController.clients.last;
              actionController.selectedClient.value = newClient;
            } else {
              actionController.selectedClient.value = previousValue;
            }
            return;
          }
          if (value is ClientModel) {
            actionController.selectedClient.value = value;
          }
        },
        validator: (value) => value == null || value == createClientValue ? "Please select a client." : null,
        items: [
          ...clientController.clients.map((ClientModel client) {
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
                    toolTipMsg: "",
                    isActive: clientController.clientSessions[client.name] ?? false,
                  ),
                ],
              ),
            );
          }),
          const DropdownMenuItem(
            value: createClientValue,
            child: Row(
              children: [
                Text("Create new client"),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildWampMethodButton(
    int tabKey,
    ActionController actionController,
  ) {
    final ActionParamsController paramsController = Get.find<ActionParamsController>(tag: "params_$tabKey");

    return Obx(() {
      final uri = actionController.uriController.text.trim();
      final selected = actionController.selectedMethod.value.toLowerCase();

      String displayMethod = selected.capitalizeFirst!;
      if (selected == "register" || selected == "unregister") {
        displayMethod = actionController.registrations.containsKey(uri) ? "Unregister" : "Register";
      } else if (selected == "subscribe" || selected == "unsubscribe") {
        displayMethod = actionController.subscriptions.containsKey(uri) ? "Unsubscribe" : "Subscribe";
      }

      return ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 48,
          maxHeight: 48,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blueAccent.shade700,
                Colors.blueAccent.shade400,
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withAlpha((0.3 * 255).round()),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                    onTap: actionController.isActionInProgress.value
                        ? null
                        : () async {
                            if (paramsController.paramsFormKey.currentState?.validate() ?? false) {
                              List<String> args = paramsController.getArgs();
                              Map<String, String> kwArgs = paramsController.getKwArgs();

                              String actualMethod = selected;
                              if (selected == "register" && actionController.registrations.containsKey(uri)) {
                                actualMethod = "unregister";
                              } else if (selected == "unregister" && !actionController.registrations.containsKey(uri)) {
                                actualMethod = "register";
                              } else if (selected == "subscribe" && actionController.subscriptions.containsKey(uri)) {
                                actualMethod = "unsubscribe";
                              } else if (selected == "unsubscribe" &&
                                  !actionController.subscriptions.containsKey(uri)) {
                                actualMethod = "subscribe";
                              }

                              await actionController.performAction(
                                actualMethod,
                                actionController.uriController.text,
                                args,
                                kwArgs,
                              );
                            }
                          },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          displayMethod,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: actionController.isActionInProgress.value ? Colors.grey.shade400 : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 24,
                color: Colors.white.withAlpha((0.3 * 255).round()),
              ),
              PopupMenuButton<String>(
                onSelected: (String newValue) {
                  actionController.selectedMethod.value = newValue.toLowerCase();
                },
                itemBuilder: (context) {
                  return wampMethods.map((method) {
                    return PopupMenuItem<String>(
                      value: method.toLowerCase(),
                      child: Text(method, style: const TextStyle(color: Colors.white)),
                    );
                  }).toList();
                },
                color: Colors.grey.shade900,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade700),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: const Icon(Icons.arrow_drop_down, size: 24, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildParamsSection(int tabKey, ActionController actionController) {
    final ActionParamsController paramsController = Get.find<ActionParamsController>(tag: "params_$tabKey");
    final bool isMobile =
        !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: paramsController.paramsFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Arguments",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (String type) {
                      paramsController.addParam(type.toLowerCase());
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem<String>(
                        value: "arg",
                        child: Row(
                          children: [
                            Icon(Icons.add, size: 18),
                            SizedBox(width: 8),
                            Text("Add Argument"),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: "kwarg",
                        child: Row(
                          children: [
                            Icon(Icons.add, size: 18),
                            SizedBox(width: 8),
                            Text("Add Keyword Argument"),
                          ],
                        ),
                      ),
                    ],
                    color: Colors.grey.shade900,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withAlpha((0.2 * 255).round()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add, size: 18, color: Colors.blueAccent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Obx(() {
                if (paramsController.params.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Center(
                      child: Column(
                        children: [
                          Text(
                            "No arguments added",
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Add arguments or keyword arguments to begin",
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: List.generate(paramsController.params.length, (index) {
                    final param = paramsController.params[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            margin: const EdgeInsets.only(right: 8, top: 8),
                            decoration: BoxDecoration(
                              color: param.type == "arg"
                                  ? Colors.blueAccent.withAlpha((0.2 * 255).round())
                                  : Colors.purpleAccent.withAlpha((0.2 * 255).round()),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                param.type == "arg" ? "A" : "K",
                                style: TextStyle(
                                  color: param.type == "arg" ? Colors.blueAccent : Colors.purpleAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: param.type == "arg"
                                ? TextFormField(
                                    controller: param.argController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: "Argument ${index + 1}",
                                      hintText: "Enter value",
                                    ),
                                    validator: param.validateArg,
                                  )
                                : isMobile
                                    ? Column(
                                        children: [
                                          TextFormField(
                                            controller: param.keyController,
                                            style: const TextStyle(color: Colors.white),
                                            decoration: const InputDecoration(
                                              labelText: "Key",
                                              hintText: "Enter key name",
                                            ),
                                            validator: param.validateKey,
                                          ),
                                          const SizedBox(height: 8),
                                          TextFormField(
                                            controller: param.valueController,
                                            style: const TextStyle(color: Colors.white),
                                            decoration: const InputDecoration(
                                              labelText: "Value",
                                              hintText: "Enter value",
                                            ),
                                            validator: param.validateValue,
                                          ),
                                        ],
                                      )
                                    : Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              controller: param.keyController,
                                              style: const TextStyle(color: Colors.white),
                                              decoration: const InputDecoration(
                                                labelText: "Key",
                                                hintText: "Enter key name",
                                              ),
                                              validator: param.validateKey,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: TextFormField(
                                              controller: param.valueController,
                                              style: const TextStyle(color: Colors.white),
                                              decoration: const InputDecoration(
                                                labelText: "Value",
                                                hintText: "Enter value",
                                              ),
                                              validator: param.validateValue,
                                            ),
                                          ),
                                        ],
                                      ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent.withAlpha((0.8 * 255).round()),
                            ),
                            onPressed: () => paramsController.removeParam(index),
                          ),
                        ],
                      ),
                    );
                  }),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogsWindow(int tabKey, ActionController actionController) {
    return _LogsWindowWidget(
      tabKey: tabKey,
      actionController: actionController,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<String>("wampMethods", wampMethods));
  }
}

class _LogsWindowWidget extends StatefulWidget {
  const _LogsWindowWidget({
    required this.tabKey,
    required this.actionController,
  });
  final int tabKey;
  final ActionController actionController;

  @override
  _LogsWindowWidgetState createState() => _LogsWindowWidgetState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<ActionController>("actionController", actionController))
      ..add(IntProperty("tabKey", tabKey));
  }
}

class _LogsWindowWidgetState extends State<_LogsWindowWidget> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  "Logs",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.clear_all, size: 20, color: Colors.grey.shade400),
                  onPressed: widget.actionController.clearLogs,
                  tooltip: "Clear logs",
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(minHeight: 120, maxHeight: 300),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha((0.3 * 255).round()),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
              child: Obx(() {
                if (widget.actionController.logs.isEmpty) {
                  return Center(
                    child: Text(
                      "No logs yet",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  );
                }
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  if (_scrollController.hasClients) {
                    await _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                    );
                  }
                });
                return ListView.builder(
                  controller: _scrollController,
                  shrinkWrap: true,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: widget.actionController.logs.length,
                  itemBuilder: (context, index) {
                    final log = widget.actionController.logs[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        log,
                        style: TextStyle(
                          color: log.toLowerCase().contains("error")
                              ? Colors.redAccent
                              : Colors.white.withAlpha((0.8 * 255).round()),
                          fontSize: 13,
                          fontFamily: "monospace",
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
