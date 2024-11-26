import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'profile_controller.dart';

class ProfileView extends StatelessWidget {
  final ProfileController controller = Get.find<ProfileController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profiles')),
      body: Obx(() {
        return ListView.builder(
          itemCount: controller.profiles.length,
          itemBuilder: (context, index) {
            final profile = controller.profiles[index];
            bool isConnected =
                controller.connectionStates[profile.authid] != null
                    ? true
                    : false;

            return ListTile(
              title: Text(profile.realm),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('URL: ${profile.url}'),
                  Text('Auth ID: ${profile.authid}'),
                  Text('Auth Method: ${profile.authmethod}'),
                  Text('Serializer: ${profile.serializer}'),
                  Text('Secret: ${profile.secret}'),
                ],
              ),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {
                      controller.createProfile(profile: profile);
                    },
                  ),
                  Obx(() {
                    return IconButton(
                        icon: Icon(controller.myConnection.value == true
                            ? Icons.stop
                            : Icons.play_arrow),
                        onPressed: () {
                          controller.toggleConnection(profile);
                        });
                  }),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => controller.deleteProfile(profile),
                  ),
                ],
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => controller.createProfile(),
        child: Icon(Icons.add),
      ),
    );
  }
}
