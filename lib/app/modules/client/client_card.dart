import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart";
import "package:wick_ui/app/data/models/client_model.dart";
import "package:wick_ui/app/modules/client/client_controller.dart";
import "package:wick_ui/utils/infow_row.dart";
import "package:wick_ui/utils/status_indicator.dart";

class ClientCard extends StatelessWidget {
  const ClientCard({
    required this.controller,
    required Key key,
    required this.client,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  }) : super(key: key);

  final ClientController controller;
  final ClientModel client;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final errorMessage = controller.errorMessages[client.name];
      final isConnected = controller.clientSessions[client.name] ?? false;
      final isConnecting = controller.connectingClient.contains(client);
      return Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      client.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (errorMessage != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Error: $errorMessage",
                          style: TextStyle(
                            color: Colors.red[400],
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(width: 8),
                        const StatusIndicator(
                          isActive: false,
                          color: Colors.red,
                          toolTipMsg: "Disconnected",
                        ),
                      ],
                    )
                  else if (isConnecting)
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Connecting...",
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        SizedBox(width: 8),
                        StatusIndicator(
                          isActive: false,
                          color: Colors.orange,
                          toolTipMsg: "Connecting",
                        ),
                      ],
                    )
                  else
                    StatusIndicator(
                      isActive: isConnected,
                      toolTipMsg: "Connected",
                    ),
                ],
              ),
              const SizedBox(height: 12),
              InfoRow(icon: Icons.public, label: "Realm", value: client.realm),
              InfoRow(icon: Icons.link, label: "URI", value: client.uri),
              InfoRow(
                icon: Icons.account_circle,
                label: "Auth ID",
                value: client.authid,
              ),
              InfoRow(
                icon: Icons.data_usage,
                label: "Auth Method",
                value: client.authmethod,
              ),
              InfoRow(icon: Icons.data_array, label: "Serializer", value: client.serializer),
              const Divider(height: 16),
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
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: onDelete,
                      ),
                      Switch.adaptive(
                        value: isConnected,
                        onChanged: (value) => onToggle(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<ClientController>("controller", controller))
      ..add(DiagnosticsProperty<ClientModel>("client", client))
      ..add(ObjectFlagProperty<VoidCallback>.has("onEdit", onEdit))
      ..add(ObjectFlagProperty<VoidCallback>.has("onDelete", onDelete))
      ..add(ObjectFlagProperty<VoidCallback>.has("onToggle", onToggle));
  }
}
