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
      title: "Profiles",
      body: Obx(() {
        if (controller.profiles.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("No profiles created yet."),
              ],
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView.separated(
              itemCount: controller.profiles.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final profile = controller.profiles[index];

                return Obx(() {
                  final isConnected = controller.connectedProfiles.contains(profile);
                  final isConnecting = controller.connectingProfiles.contains(profile);
                  final errorMessage = controller.errorMessages[profile.name];

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      title: Row(
                        children: [
                          Text(
                            profile.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isConnecting)
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Text(
                                "Connecting...",
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            )
                          else if (errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                "Error: $errorMessage",
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            )
                          else
                            CircleAvatar(
                              radius: 5,
                              backgroundColor: isConnected ? Colors.green : Colors.red,
                            ),
                        ],
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
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () async {
                              await controller.createProfile(profile: profile);
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              isConnected ? Icons.stop : Icons.play_arrow,
                              color: isConnected ? Colors.red : Colors.green,
                            ),
                            onPressed: () async => controller.toggleConnection(profile),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.blueGrey),
                            onPressed: () async => controller.deleteProfile(profile),
                          ),
                        ],
                      ),
                    ),
                  );
                });
              },
            ),
          );
        }
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
