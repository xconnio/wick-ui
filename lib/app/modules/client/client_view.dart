import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:wick_ui/app/modules/client/client_card.dart";
import "package:wick_ui/app/modules/client/client_controller.dart";
import "package:wick_ui/config/theme/my_theme.dart"; // <- Import your centralized theme
import "package:wick_ui/utils/responsive_scaffold.dart";

class ClientView extends StatelessWidget {
  ClientView({super.key});

  final ClientController controller = Get.find<ClientController>();

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: MyTheme.dark(),
      child: ResponsiveScaffold(
        body: Obx(() {
          if (controller.clients.isEmpty) {
            return const Center(
              child: Text("No clients created yet.", style: TextStyle(color: Colors.white)),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView.builder(
              itemCount: controller.clients.length,
              itemBuilder: (context, index) {
                final client = controller.clients[index];
                final isConnecting = controller.connectingClient.contains(client);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ClientCard(
                    controller: controller,
                    key: ValueKey(client.name),
                    client: client,
                    isConnecting: isConnecting,
                    onEdit: () async => controller.createClient(client: client),
                    onDelete: () async => controller.deleteClient(client),
                    onToggle: () async => controller.toggleConnection(client),
                  ),
                );
              },
            ),
          );
        }),
        floatingActionButton: FloatingActionButton(
          tooltip: "Create a new client",
          onPressed: controller.createClient,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ClientController>("controller", controller));
  }
}
