import 'package:get/get.dart';
import '../../../utils/session_manager.dart';
import '../../../utils/storage_manager.dart';
import '../../data/models/profile_model.dart';
import 'package:flutter/material.dart';
import 'package:xconn/xconn.dart';

class ProfileController extends GetxController {
  var profiles = <ProfileModel>[].obs;
  var connectedProfiles = <ProfileModel>[].obs; // List of connected profiles

  @override
  void onInit() {
    super.onInit();
    loadProfiles();
  }

  Future<void> saveProfiles() async {
    await StorageManager.saveProfiles(profiles);
  }

  Future<void> loadProfiles() async {
    profiles.assignAll(await StorageManager.loadProfiles());
  }

  Future<void> addProfile(ProfileModel profile) async {
    profiles.add(profile);
    await saveProfiles();
    Get.snackbar(
        'Profile Saved', 'Profile for ${profile.authid} saved successfully!',
        snackPosition: SnackPosition.BOTTOM, duration: Duration(seconds: 1));
  }

  Future<void> updateProfile(ProfileModel profile) async {
    int index = profiles.indexWhere((p) => p.authid == profile.authid);
    if (index != -1) {
      profiles[index] = profile;
      await saveProfiles();
      Get.snackbar('Profile Updated',
          'Profile for ${profile.authid} updated successfully!',
          snackPosition: SnackPosition.BOTTOM, duration: Duration(seconds: 1));
    }
  }

  Future<void> deleteProfile(ProfileModel profile) async {
    profiles.removeWhere((p) => p.authid == profile.authid);
    connectedProfiles.remove(profile); // Remove from connected if exists
    await saveProfiles();
    Get.snackbar('Profile Deleted',
        'Profile for ${profile.authid} deleted successfully!',
        snackPosition: SnackPosition.BOTTOM, duration: Duration(seconds: 1));
  }

  void toggleConnection(ProfileModel profile) async {
    if (connectedProfiles.contains(profile)) {
// Disconnect the session
      connectedProfiles.remove(profile);
      Get.snackbar('Connection Status', 'Disconnected successfully!',
          snackPosition: SnackPosition.BOTTOM, duration: Duration(seconds: 1));
    } else {
      try {
        var session = await SessionManager.connect(profile);
        connectedProfiles.add(profile);
        Get.snackbar('Connection Status', 'Connected successfully!',
            snackPosition: SnackPosition.BOTTOM,
            duration: Duration(seconds: 1));
      } catch (e) {
        print('Failed to connect: $e');
        Get.snackbar('Error', 'Failed to connect.',
            snackPosition: SnackPosition.BOTTOM,
            duration: Duration(microseconds: 1));
      }
    }
  }

  void createProfile({ProfileModel? profile}) {
    final formKey = GlobalKey<FormState>();
    final urlController = TextEditingController(text: profile?.url ?? '');
    final realmController = TextEditingController(text: profile?.realm ?? '');
    final authidController = TextEditingController(text: profile?.authid ?? '');
    final secretController = TextEditingController(text: profile?.secret ?? '');

    final serializers = ['JSON', 'MsgPack', 'CBOR'];
    final authMethods = ['Anonymous', 'Ticket', 'WAMP-CRA', 'CryptoSign'];

    var selectedSerializer = serializers.contains(profile?.serializer)
        ? profile?.serializer ?? serializers.first
        : serializers.first;
    var selectedAuthMethod = authMethods.contains(profile?.authmethod)
        ? profile?.authmethod ?? authMethods.first
        : authMethods.first;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(profile == null
                ? 'Create WAMP Session'
                : 'Update WAMP Session'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: urlController,
                      decoration: InputDecoration(labelText: 'URL'),
                      validator: (value) =>
                      value!.isEmpty ? 'Please enter a URL' : null,
                    ),
                    TextFormField(
                      controller: realmController,
                      decoration: InputDecoration(labelText: 'Realm'),
                      validator: (value) =>
                      value!.isEmpty ? 'Please enter a realm' : null,
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedSerializer,
                      decoration: InputDecoration(labelText: 'Serializer'),
                      items: serializers.map((serializer) {
                        return DropdownMenuItem<String>(
                          value: serializer,
                          child: Text(serializer),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedSerializer = value!;
                        });
                      },
                      validator: (value) =>
                      value == null ? 'Please select a serializer' : null,
                    ),
                    TextFormField(
                      controller: authidController,
                      decoration: InputDecoration(labelText: 'Auth ID'),
                      validator: (value) =>
                      value!.isEmpty ? 'Please enter an auth ID' : null,
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedAuthMethod,
                      decoration: InputDecoration(labelText: 'Auth Method'),
                      items: authMethods.map((authMethod) {
                        return DropdownMenuItem<String>(
                          value: authMethod,
                          child: Text(authMethod),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedAuthMethod = value!;
                        });
                      },
                      validator: (value) => value == null
                          ? 'Please select an authentication method'
                          : null,
                    ),
                    if (selectedAuthMethod == 'Ticket')
                      TextFormField(
                        controller: secretController,
                        decoration: InputDecoration(labelText: 'Ticket'),
                        validator: (value) =>
                        value!.isEmpty ? 'Please enter a ticket' : null,
                      ),
                    if (selectedAuthMethod == 'WAMP-CRA')
                      TextFormField(
                        controller: secretController,
                        decoration: InputDecoration(labelText: 'Secret'),
                        validator: (value) =>
                        value!.isEmpty ? 'Please enter a secret' : null,
                      ),
                    if (selectedAuthMethod == 'CryptoSign')
                      TextFormField(
                        controller: secretController,
                        decoration: InputDecoration(labelText: 'PrivateKey'),
                        validator: (value) =>
                        value!.isEmpty ? 'PrivateKey required' : null,
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Get.back();
                },
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    Get.back(); // Close the dialog first
                    try {
                      final newProfile = ProfileModel(
                        url: urlController.text,
                        realm: realmController.text,
                        serializer: selectedSerializer,
                        authid: authidController.text,
                        authmethod: selectedAuthMethod,
                        secret: secretController.text,
                      );

                      if (profile == null) {
                        await addProfile(newProfile);
                      } else {
                        await updateProfile(newProfile);
                      }

                      Get.snackbar('Profile Saved',
                          'Profile for ${newProfile.authid} saved successfully!',
                          snackPosition: SnackPosition.BOTTOM,
                          duration: Duration(seconds: 1));
                    } catch (e) {
                      Get.snackbar('Error', 'Failed to save profile: $e',
                          snackPosition: SnackPosition.BOTTOM,
                          duration: Duration(seconds: 1));
                    }
                  }
                },
                child: Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}
