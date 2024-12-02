import "package:flutter/material.dart";
import "package:get/get.dart";
import "../../../utils/session_manager.dart";
import "../../../utils/storage_manager.dart";
import "../../data/models/profile_model.dart";

class ProfileController extends GetxController {
  var profiles = <ProfileModel>[].obs;
  var connectedProfiles = <ProfileModel>[].obs;
  static const snakbarDisplayTime = Duration(seconds: 1);

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
      "Profile",
      "${profile.name} added successfully!",
      snackPosition: SnackPosition.BOTTOM,
      duration: snakbarDisplayTime,
    );
  }

  Future<void> updateProfile(ProfileModel updatedProfile) async {
    int index = profiles.indexWhere((p) => p.name == updatedProfile.name);
    if (index != -1) {
      profiles[index] = updatedProfile;
      await saveProfiles();
      Get.snackbar(
        "Profile",
        "${updatedProfile.name} updated successfully!",
        snackPosition: SnackPosition.BOTTOM,
        duration: snakbarDisplayTime,
      );
    }
  }

  Future<void> deleteProfile(ProfileModel profile) async {
    profiles.removeWhere((p) => p.name == profile.name);
    connectedProfiles.remove(profile);
    await saveProfiles();
    Get.snackbar(
      "Profile",
      "${profile.name} deleted!",
      snackPosition: SnackPosition.BOTTOM,
      duration: snakbarDisplayTime,
    );
  }

  void toggleConnection(ProfileModel profile) async {
    if (connectedProfiles.contains(profile)) {
      connectedProfiles.remove(profile);
      Get.snackbar(
        "Connection Status",
        "Profile ${profile.name} disconnected!",
        snackPosition: SnackPosition.BOTTOM,
        duration: snakbarDisplayTime,
      );
    } else {
      try {
        var session = await SessionManager.connect(profile);
        connectedProfiles.add(profile);
        Get.snackbar(
          "Connection Status",
          "Profile ${profile.name} connected successfully!",
          snackPosition: SnackPosition.BOTTOM,
          duration: snakbarDisplayTime,
        );
      } catch (e) {
        Get.snackbar(
          "Error",
          "Failed to connect: $e",
          snackPosition: SnackPosition.BOTTOM,
          duration: snakbarDisplayTime,
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
              child: Container(
                width: 100,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration:
                            const InputDecoration(labelText: "Profile Name"),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Please enter a profile name";
                          }
                          if (profiles
                              .any((p) => p.name == value && p != profile)) {
                            return "Profile name already exists. Choose a different name.";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: urlController,
                        decoration:
                            const InputDecoration(labelText: "WAMP URL"),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Please enter a URL";
                          }
                          if (!value.startsWith("ws://") &&
                              !value.startsWith("wss://")) {
                            return "URL must start with ws:// or wss://";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: realmController,
                        decoration: InputDecoration(labelText: "Realm"),
                        validator: (value) =>
                            value!.isEmpty ? "Please enter a realm" : null,
                      ),
                      SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedSerializer,
                        decoration: InputDecoration(labelText: "Serializer"),
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
                      SizedBox(height: 8),
                      TextFormField(
                        controller: authidController,
                        decoration: InputDecoration(labelText: "Auth ID"),
                        validator: (value) {
                          if (selectedAuthMethod != "Anonymous" &&
                              (value == null || value.isEmpty)) {
                            return "Please enter an Auth ID";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 8),
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
                        validator: (value) => value == null
                            ? "Please select an authentication method"
                            : null,
                      ),
                      if (selectedAuthMethod == "Ticket") SizedBox(height: 8),
                      if (selectedAuthMethod == "Ticket")
                        TextFormField(
                          controller: secretController,
                          decoration:
                              const InputDecoration(labelText: "Ticket"),
                          validator: (value) =>
                              value!.isEmpty ? "Please enter a ticket" : null,
                        ),
                      if (selectedAuthMethod == "WAMP-CRA") SizedBox(height: 8),
                      if (selectedAuthMethod == "WAMP-CRA")
                        TextFormField(
                          controller: secretController,
                          decoration:
                              const InputDecoration(labelText: "Secret"),
                          validator: (value) =>
                              value!.isEmpty ? "Please enter a secret" : null,
                        ),
                      if (selectedAuthMethod == "CryptoSign")
                        SizedBox(height: 8),
                      if (selectedAuthMethod == "CryptoSign")
                        TextFormField(
                          controller: secretController,
                          decoration:
                              const InputDecoration(labelText: "PrivateKey"),
                          validator: (value) =>
                              value!.isEmpty ? "PrivateKey required" : null,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: Get.back,
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    Get.back(); // Close the dialog first
                    try {
                      final newProfile = ProfileModel(
                        name: nameController.text,
                        url: urlController.text,
                        realm: realmController.text,
                        serializer: selectedSerializer,
                        authid: authidController.text,
                        authmethod: selectedAuthMethod,
                        secret: secretController.text,
                      );
                      print(newProfile.secret);

                      if (profile == null) {
                        await addProfile(newProfile);
                      } else {
                        await updateProfile(newProfile);
                      }
                    } catch (e) {
                      Get.snackbar(
                        "Error",
                        "Failed to save profile: $e",
                        snackPosition: SnackPosition.BOTTOM,
                        duration: snakbarDisplayTime,
                      );
                    }
                  }
                },
                child: Text("Save"),
              ),
            ],
          );
        },
      ),
    );
  }
}
