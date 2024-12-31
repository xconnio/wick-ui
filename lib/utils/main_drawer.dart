import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:wick_ui/app/routes/app_routes.dart";

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key, this.isSidebar = true});

  final bool isSidebar;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (!isSidebar)
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Text(
                "Wick", // Replace with your actual app title
                style: TextStyle(
                  color: Theme.of(context).primaryTextTheme.titleLarge?.color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Profile"),
            onTap: () async {
              await Get.offAllNamed(AppRoutes.profile);
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_tree),
            title: const Text("Action"),
            onTap: () async {
              await Get.offAllNamed(AppRoutes.action);
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
