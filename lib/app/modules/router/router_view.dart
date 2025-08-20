import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:wick_ui/app/modules/router/router_card.dart";
import "package:wick_ui/app/modules/router/router_controller.dart";
import "package:wick_ui/config/theme/my_theme.dart";
import "package:wick_ui/utils/responsive_scaffold.dart";

class RouterView extends StatelessWidget {
  RouterView({super.key});

  final RouterController controller = Get.put(RouterController());

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: MyTheme.dark(),
      child: ResponsiveScaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Obx(
            () => ListView.builder(
              itemCount: controller.routerConfigs.length,
              itemBuilder: (context, index) {
                final config = controller.routerConfigs[index];
                final realm = config.realms.firstOrNull;
                final transport = config.transports.firstOrNull;

                if (realm == null) {
                  return const SizedBox.shrink();
                }

                final isRunning = controller.runningRouters[realm.name] ?? false;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: RouterCard(
                    controller: controller,
                    key: ValueKey(realm.name),
                    routerName: config.name,
                    realmName: realm.name,
                    status: isRunning ? "Running" : "Stopped",
                    realm: realm.name,
                    port: transport?.port.toString() ?? "N/A",
                    serializers: transport?.serializers.join(", ") ?? "None",
                    isActive: isRunning,
                    onEdit: () => controller.createRouterConfig(index: index),
                    onToggle: () async {
                      if (isRunning) {
                        await controller.stopRouter(realm.name);
                      } else {
                        await controller.runRouter(realm);
                      }
                    },
                    onDelete: () => controller.deleteRouterConfig(index),
                  ),
                );
              },
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: controller.createRouterConfig,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<RouterController>("controller", controller));
  }
}
