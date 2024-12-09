import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:get/get.dart";

import "package:wick_ui/app/routes/app_routes.dart";

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key, this.isSidebar = true});

  final bool isSidebar;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isSidebar ? 250 : null,
      color: isSidebar ? Colors.white : null,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text("Welcome"),
            onTap: () async {
              await Get.toNamed(AppRoutes.welcome);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Profile"),
            onTap: () async {
              await Get.toNamed(AppRoutes.profile);
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
