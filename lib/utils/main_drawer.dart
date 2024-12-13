import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:wick_ui/app/routes/app_routes.dart";

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key, this.isSidebar = true});

  final bool isSidebar;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isSidebar ? 250 : null,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Profile"),
            onTap: () async {
              await Get.toNamed(AppRoutes.profile);
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_tree),
            title: const Text("Action"),
            onTap: () async {
              await Get.toNamed(AppRoutes.action);
            },
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>("isSidebar", isSidebar));
  }
}
