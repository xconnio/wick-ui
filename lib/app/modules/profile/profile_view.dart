import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:wick_ui/app/modules/profile/profile_controller.dart";
import "package:wick_ui/config/theme/dark_theme_colors.dart";
import "package:wick_ui/utils/responsive_scaffold.dart";

class ProfileView extends StatelessWidget {
  ProfileView({super.key});

  final ProfileController controller = Get.find<ProfileController>();

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      body: Obx(() {
        return controller.profiles.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("No profiles created yet."),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: controller.profiles.length,
                itemBuilder: (context, index) {
                  final profile = controller.profiles[index];

                  return ListTile(
                    title: Text(
                      profile.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Realm: ${profile.realm}"),
                        Text("URL: ${profile.url}"),
                        Text("Auth ID: ${profile.authid}"),
                        Text("Auth Method: ${profile.authmethod}"),
                        Text("Serializer: ${profile.serializer}"),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: Obx(() {
                      bool isConnected = controller.connectedProfiles.contains(profile);
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () async {
                              await controller.createProfile(profile: profile);
                            },
                          ),
                          IconButton(
                            icon: Icon(isConnected ? Icons.stop : Icons.play_arrow),
                            onPressed: () async => controller.toggleConnection(profile),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () async => controller.deleteProfile(profile),
                          ),
                        ],
                      );
                    }),
                  );
                },
              );
      }),
      floatingActionButton: FloatingActionButton(
        backgroundColor: DarkThemeColors.primaryColor,
        onPressed: controller.createProfile,
        child: const Icon(Icons.add, color: DarkThemeColors.onPrimaryColor),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ProfileController>("controller", controller));
  }
}
