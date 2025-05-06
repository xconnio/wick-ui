import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:wick_ui/app/data/models/client_model.dart";
import "package:wick_ui/app/modules/action/action_controller.dart";
import "package:wick_ui/app/modules/action/action_params_controller.dart";
import "package:wick_ui/app/modules/client/client_controller.dart";
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
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212), // Darker background
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E), // Slightly lighter than scaffold
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white, fontSize: 14),
          titleLarge: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade900.withAlpha((0.5 * 255).round()),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade700),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
          ),
          labelStyle: TextStyle(color: Colors.grey.shade400),
          hintStyle: TextStyle(color: Colors.grey.shade500),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 2,
          ),
        ),
        cardTheme: CardTheme(
          color: Colors.grey.shade900,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: EdgeInsets.zero,
        ),
        dividerTheme: DividerThemeData(
          color: Colors.grey.shade800,
          thickness: 1,
          space: 1,
        ),
      ),
      child: ResponsiveScaffold(
        title: "Actions",
        body: TabContainerWidget(
          buildScreen: _buildScreen,
        ),
      ),
    );
  }

  Widget _buildScreen(BuildContext context, int tabKey) {
    if (!Get.isRegistered<ActionParamsController>(tag: "params_$tabKey")) {
      Get.put(ActionParamsController(), tag: "params_$tabKey");
    }
    if (!Get.isRegistered<ActionController>(tag: "action_$tabKey")) {
      Get.put(ActionController(), tag: "action_$tabKey");
    }

    final ActionController actionController = Get.find<ActionController>(tag: "action_$tabKey");
    final ClientController clientController = Get.find<ClientController>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildUriBar(tabKey, actionController, clientController),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(
            child: Obx(() {
              if (actionController.errorMessage.value.isNotEmpty) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900.withAlpha((0.3 * 255).round()),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.redAccent),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          actionController.errorMessage.value,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(child: _buildParamsSection(tabKey, actionController)),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(child: _buildLogsWindow(tabKey, actionController)),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: formKey,
          child: Column(
            children: isMobile
                ? [
              TextFormField(
                controller: actionController.uriController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "URI",
                  hintText: "Enter WAMP URI",
                  prefixIcon: Icon(Icons.link, size: 20),
                ),
                validator: (value) => value == null || value.isEmpty ? "URI cannot be empty." : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildDropdown(tabKey, actionController, clientController),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _buildWampMethodButton(tabKey, formKey, actionController),
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
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: TextFormField(
                      controller: actionController.uriController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "URI",
                        hintText: "Enter WAMP URI",
                        prefixIcon: Icon(Icons.link, size: 20),
                      ),
                      validator: (value) => value == null || value.isEmpty ? "URI cannot be empty." : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _buildWampMethodButton(tabKey, formKey, actionController),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(int tabKey, ActionController actionController, ClientController clientController) {
    return Obx(() {
      return DropdownButtonFormField<ClientModel>(
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
        onChanged: (ClientModel? newValue) async {
          if (newValue != null) {
            await actionController.setSelectedClient(newValue);
          }
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

  Widget _buildWampMethodButton(int tabKey, GlobalKey<FormState> formKey, ActionController actionController) {
    final ActionParamsController paramsController = Get.find<ActionParamsController>(tag: "params_$tabKey");

    return Obx(() {
      return SizedBox(
        height: 56, // Match the height of other form fields
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
                blurRadius: 4,
                offset: const Offset(0, 2),
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
                        ? null // Disable tap when action is in progress
                        : () async {
                      if (formKey.currentState?.validate() ?? false) {
                        List<String> args = paramsController.getArgs();
                        Map<String, String> kwArgs = paramsController.getKwArgs();

                        await actionController.performAction(
                          actionController.selectedMethod.value.toLowerCase(),
                          actionController.uriController.text,
                          args,
                          kwArgs,
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          actionController.selectedMethod.value,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: actionController.isActionInProgress.value
                                ? Colors.grey.shade400 // Dimmed color when disabled
                                : Colors.white,
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
                onSelected: actionController.isActionInProgress.value
                    ? null // Disable menu when action is in progress
                    : (String newValue) async {
                  if (formKey.currentState?.validate() ?? false) {
                    List<String> args = paramsController.getArgs();
                    Map<String, String> kwArgs = paramsController.getKwArgs();

                    await actionController.performAction(
                      newValue.toLowerCase(),
                      actionController.uriController.text,
                      args,
                      kwArgs,
                    );
                  }
                },
                itemBuilder: (context) {
                  return wampMethods.map((method) {
                    return PopupMenuItem<String>(
                      value: method,
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: param.valueController,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  labelText: "Value",
                                  hintText: "Enter value",
                                ),
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
  final int tabKey;
  final ActionController actionController;

  const _LogsWindowWidget({
    required this.tabKey,
    required this.actionController,
  });

  @override
  _LogsWindowWidgetState createState() => _LogsWindowWidgetState();
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
                  "Execution Logs",
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
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
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