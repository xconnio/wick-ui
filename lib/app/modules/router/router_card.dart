import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:wick_ui/app/modules/router/router_controller.dart";
import "package:wick_ui/utils/infow_row.dart";
import "package:wick_ui/utils/status_indicator.dart";

class RouterCard extends StatelessWidget {
  const RouterCard({
    required this.controller,
    required Key key,
    required this.realmName,
    required this.status,
    required this.realm,
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
  final String realm;
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
                  () => StatusIndicator(
                    toolTipMsg: "",
                    isActive: controller.runningRouters[realmName] ?? false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InfoRow(icon: Icons.settings_ethernet, label: "realm", value: port),
            InfoRow(
              icon: Icons.data_array,
              label: "Realm",
              value: realmName,
            ),
            const SizedBox(height: 12),
            InfoRow(icon: Icons.settings_ethernet, label: "Port", value: port),
            InfoRow(
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
      ..add(ObjectFlagProperty<VoidCallback>.has("onDelete", onDelete))
      ..add(StringProperty("realm", realm));
  }
}
