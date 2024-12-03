import "package:flutter/material.dart";
import "package:get/get.dart";
import 'package:wick_ui/utils/session_manager.dart';
import 'package:wick_ui/utils/storage_manager.dart';
import 'package:wick_ui/app/data/models/profile_model.dart';

class ProfileController extends GetxController {
  var profiles = <ProfileModel>[].obs;
  var connectedProfiles = <ProfileModel>[].obs; // List of connected profiles

  @override
  void onInit() {
    super.onInit();
    loadProfiles();
  }

  Future<void> saveProfiles() async {
    await StorageManager.saveProfiles(profiles.toList());
  }

  Future<void> loadProfiles() async {
    profiles.assignAll(await StorageManager.loadProfiles());
  }

  Future<void> addProfile(ProfileModel profile) async {
    profiles.add(profile);
    await saveProfiles();
    Get.snackbar(
      "Profile Saved",
      "Profile for ${profile.name} added successfully!",
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 1),
    );
  }

  Future<void> updateProfile(ProfileModel updatedProfile) async {
    int index = profiles.indexWhere((p) => p.name == updatedProfile.name);
    if (index != -1) {
      profiles[index] = updatedProfile;
      await saveProfiles();
      Get.snackbar(
        "Profile Updated",
        "Profile for ${updatedProfile.name} updated successfully!",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 1),
      );
    }
  }

  Future<void> deleteProfile(ProfileModel profile) async {
    profiles.removeWhere((p) => p.name == profile.name);
    connectedProfiles.remove(profile);
    await saveProfiles();
    Get.snackbar(
      "Profile Deleted",
      "Profile for ${profile.name} deleted successfully!",
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 1),
    );
  }

  void toggleConnection(ProfileModel profile) async {
    if (connectedProfiles.contains(profile)) {
      connectedProfiles.remove(profile);
      Get.snackbar(
        "Connection Status",
        "Disconnected from ${profile.name}!",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 1),
      );
    } else {
      try {
        await SessionManager.connect(profile);
        connectedProfiles.add(profile);
        Get.snackbar(
          "Connection Status",
          "Connected to ${profile.name}!",
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 1),
        );
      } catch (e) {
        Get.snackbar(
          "Error",
          "Failed to connect: $e",
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 1),
        );
      }
    }
  }

  void createProfile({ProfileModel? profile}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: profile?.name ?? "");
    final urlController = TextEditingController(text: profile?.url ?? "");
    final realmController = TextEditingController(text: profile?.realm ?? "");
    final authidController = TextEditingController(text: profile?.authid ?? "");
    final secretController = TextEditingController(text: profile?.secret ?? "");

    final serializers = ["JSON", "MsgPack", "CBOR"];
    final authMethods = ["Anonymous", "Ticket", "WAMP-CRA", "CryptoSign"];

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
            title: Text(profile == null ? "Create Profile" : "Update Profile"),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "Name"),
                      validator: (value) {
                        if (value!.isEmpty) return "Please enter a name";
                        if (profiles.any((p) =>
                            p.name == value && p.name != profile?.name)) {
                          return "Name already exists. Choose a different name.";
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: urlController,
                      decoration: const InputDecoration(labelText: "URL"),
                      validator: (value) {
                        if (value!.isEmpty) return "Please enter a URL";
                        if (!value.startsWith("ws://") &&
                            !value.startsWith("wss://")) {
                          return "URL must start with ws:// or wss://";
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: realmController,
                      decoration: const InputDecoration(labelText: "Realm"),
                      validator: (value) =>
                          value!.isEmpty ? "Please enter a realm" : null,
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedSerializer,
                      decoration:
                          const InputDecoration(labelText: "Serializer"),
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
                          value == null ? "Please select a serializer" : null,
                    ),
                    TextFormField(
                      controller: authidController,
                      decoration: const InputDecoration(labelText: "Auth ID"),
                      validator: (value) {
                        if (selectedAuthMethod != "Anonymous" &&
                            (value == null || value.isEmpty)) {
                          return "Please enter an Auth ID";
                        }
                        return null;
                      },
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedAuthMethod,
                      decoration:
                          const InputDecoration(labelText: "Auth Method"),
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
                      validator: (value) =>
                          value == null ? "Please select an auth method" : null,
                    ),
                    if (selectedAuthMethod != "Anonymous")
                      TextFormField(
                        controller: secretController,
                        decoration: const InputDecoration(labelText: "Secret"),
                        validator: (value) =>
                            value!.isEmpty ? "Please enter a secret" : null,
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: Get.back,
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    Get.back(); // Close the dialog first
                    final newProfile = ProfileModel(
                      name: nameController.text,
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
                  }
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      ),
    );
  }
}
