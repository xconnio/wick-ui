import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:wick_ui/app/modules/profile/profile_card.dart";
import "package:wick_ui/app/modules/profile/profile_controller.dart";
import "package:wick_ui/utils/responsive_scaffold.dart";

class ProfileView extends StatelessWidget {
  ProfileView({super.key});

  final ProfileController controller = Get.find<ProfileController>();

  @override
  Widget build(BuildContext context) {
    controller.refreshSessions();

    return ResponsiveScaffold(
      title: "Profiles",
      body: Obx(() {
        if (controller.profiles.isEmpty) {
          return const Center(child: Text("No profiles created yet."));
        } else {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView.separated(
              itemCount: controller.profiles.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final profile = controller.profiles[index];
                final isConnecting = controller.connectingProfiles.contains(profile);
                final errorMessage = controller.errorMessages[profile.name];

                return ProfileCard(
                  controller: controller,
                  key: ValueKey(profile.name),
                  profile: profile,
                  isConnecting: isConnecting,
                  errorMessage: errorMessage,
                  onEdit: () async {
                    await controller.createProfile(profile: profile);
                  },
                  onDelete: () async {
                    await controller.deleteProfile(profile);
                  },
                  onToggle: () async {
                    await controller.toggleConnection(profile);
                  },
                );
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
