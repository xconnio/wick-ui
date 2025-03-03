import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:wick_ui/app/modules/profile/profile_controller.dart";
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
            child: Text("No profiles created yet."),
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
                                  profile.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (isConnecting) const Text(
                                "Connecting...",
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ) else _StatusIndicator(isActive: isConnected),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text("Realm: ${profile.realm}"),
                          Text("URI: ${profile.uri}"),
                          Text("Auth ID: ${profile.authid}"),
                          Text("Auth Method: ${profile.authmethod}"),
                          Text("Serializer: ${profile.serializer}"),
                          if (errorMessage != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              "Error: $errorMessage",
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              FilledButton.tonalIcon(
                                icon: const Icon(Icons.edit, size: 18),
                                label: const Text("Edit"),
                                onPressed: () async {
                                  await controller.createProfile(profile: profile);
                                },
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.blueGrey),
                                    onPressed: () async => controller.deleteProfile(profile),
                                  ),
                                  Switch.adaptive(
                                    value: isConnected,
                                    onChanged: (value) async => controller.toggleConnection(profile),
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
              },
            ),
          );
        }
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.createProfile,
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ProfileController>("controller", controller));
  }
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({required this.isActive});
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: isActive ? Colors.green.shade600 : Colors.red,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          isActive ? "ACTIVE" : "INACTIVE",
          style: TextStyle(
            color: isActive ? Colors.green.shade600 : Colors.grey,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>("isActive", isActive));
  }
}
