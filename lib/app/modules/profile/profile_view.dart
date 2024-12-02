import "package:flutter/material.dart";
import "package:get/get.dart";
import "profile_controller.dart";

class ProfileView extends StatelessWidget {
  final ProfileController controller = Get.find<ProfileController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profiles")),
      body: Obx(() {
        return ListView.builder(
          itemCount: controller.profiles.length,
          itemBuilder: (context, index) {
            final profile = controller.profiles[index];

            return ListTile(
              title: Text(
                profile.name,
                style: TextStyle(
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
                  Text("Secret: ${profile.secret}"),
                ],
              ),
              isThreeLine: true,
              trailing: Obx(() {
                bool isConnected =
                    controller.connectedProfiles.contains(profile);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        controller.createProfile(profile: profile);
                      },
                    ),
                    IconButton(
                      icon: Icon(isConnected ? Icons.stop : Icons.play_arrow),
                      onPressed: () => controller.toggleConnection(profile),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => controller.deleteProfile(profile),
                    ),
                  ],
                );
              }),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.createProfile,
        child: const Icon(Icons.add),
      ),
    );
  }
}
