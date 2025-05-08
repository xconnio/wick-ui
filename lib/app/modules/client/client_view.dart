import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:wick_ui/app/modules/client/client_card.dart";
import "package:wick_ui/app/modules/client/client_controller.dart";
import "package:wick_ui/utils/responsive_scaffold.dart";

class ClientView extends StatelessWidget {
  ClientView({super.key});

  final ClientController controller = Get.find<ClientController>();

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      body: Obx(() {
        if (controller.clients.isEmpty) {
          return const Center(child: Text("No clients created yet."));
        } else {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView.separated(
              itemCount: controller.clients.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final client = controller.clients[index];
                final isConnecting = controller.connectingClient.contains(client);

                return ClientCard(
                  controller: controller,
                  key: ValueKey(client.name),
                  client: client,
                  isConnecting: isConnecting,
                  onEdit: () async {
                    await controller.createClient(client: client);
                  },
                  onDelete: () async {
                    await controller.deleteClient(client);
                  },
                  onToggle: () async {
                    await controller.toggleConnection(client);
                  },
                );
              },
            ),
          );
        }
      }),
      floatingActionButton: FloatingActionButton(
        tooltip: "Create a new client",
        onPressed: controller.createClient,
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ClientController>("controller", controller));
  }
}
