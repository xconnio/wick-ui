import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:wick_ui/app/modules/router/router_controller.dart";
import "package:wick_ui/utils/responsive_scaffold.dart";

class RouterView extends StatelessWidget {
  RouterView({super.key});

  final RouterController controller = Get.put(RouterController());

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(
          () => ListView.builder(
            itemCount: controller.routerConfigs.length,
            itemBuilder: (context, index) {
              final config = controller.routerConfigs[index];
              final realm = config.realms.isNotEmpty ? config.realms.first : null;
              final transport = config.transports.isNotEmpty ? config.transports.first : null;

              if (realm == null) {
                return const SizedBox.shrink();
              }

              return _RouterCard(
                controller: controller,
                key: ValueKey(realm.name),
                realmName: realm.name,
                status: controller.runningRouters[realm.name] ?? false ? "Running" : "Stopped",
                port: transport?.port.toString() ?? "N/A",
                serializers: transport?.serializers.join(", ") ?? "None",
                isActive: controller.runningRouters[realm.name] ?? false,
                onEdit: () async => controller.createRouterConfig(index: index),
                onToggle: () async {
                  if (controller.runningRouters[realm.name] ?? false) {
                    await controller.stopRouter(realm.name);
                  } else {
                    await controller.runRouter(realm);
                  }
                },
                onDelete: () async => controller.deleteRouterConfig(index),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        tooltip: "Create a new router",
        icon: const Icon(Icons.add, size: 24),
        label: const Text("New Router"),
        onPressed: controller.createRouterConfig,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<RouterController>("controller", controller));
  }
}

class _RouterCard extends StatelessWidget {
  const _RouterCard({
    required this.controller,
    required Key key,
    required this.realmName,
    required this.status,
    required this.port,
    required this.serializers,
    required this.isActive,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  }) : super(key: key);
  final RouterController controller;

  final String realmName;
  final String status;
  final String port;
  final String serializers;
  final bool isActive;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    realmName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ),
                Obx(
                  () => _StatusIndicator(
                    isActive: controller.runningRouters[realmName] ?? false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(icon: Icons.settings_ethernet, label: "Port", value: port),
            _InfoRow(
              icon: Icons.data_array,
              label: "Serializers",
              value: serializers,
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text("Edit"),
                  onPressed: onEdit,
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: onDelete,
                      style: IconButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                      ),
                    ),
                    Obx(
                      () => Switch.adaptive(
                        value: controller.runningRouters[realmName] ?? false,
                        onChanged: (value) => onToggle(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<RouterController>("controller", controller))
      ..add(StringProperty("realmName", realmName))
      ..add(StringProperty("status", status))
      ..add(StringProperty("port", port))
      ..add(StringProperty("serializers", serializers))
      ..add(DiagnosticsProperty<bool>("isActive", isActive))
      ..add(ObjectFlagProperty<VoidCallback>.has("onEdit", onEdit))
      ..add(ObjectFlagProperty<VoidCallback>.has("onToggle", onToggle))
      ..add(ObjectFlagProperty<VoidCallback>.has("onDelete", onDelete));
  }
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: isActive ? Colors.green.shade600 : Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          isActive ? "ACTIVE" : "INACTIVE",
          style: TextStyle(
            color: isActive ? Colors.green.shade600 : Colors.grey,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>("isActive", isActive));
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade800,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<IconData>("icon", icon))
      ..add(StringProperty("label", label))
      ..add(StringProperty("value", value));
  }
}
