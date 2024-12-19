import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:wick_ui/app/data/models/profile_model.dart";
import "package:wick_ui/utils/session_manager.dart";
import "package:wick_ui/utils/storage_manager.dart";

class ProfileController extends GetxController {
  RxList<ProfileModel> profiles = <ProfileModel>[].obs;
  RxList<ProfileModel> connectedProfiles = <ProfileModel>[].obs;
  RxList<ProfileModel> connectingProfiles = <ProfileModel>[].obs;
  RxMap<String, String> errorMessages = <String, String>{}.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    await loadProfiles();
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
  }

  Future<void> updateProfile(ProfileModel updatedProfile) async {
    int index = profiles.indexWhere((p) => p.name == updatedProfile.name);
    if (index != -1) {
      profiles[index] = updatedProfile;
      await saveProfiles();
    }
  }

  Future<void> deleteProfile(ProfileModel profile) async {
    profiles.removeWhere((p) => p.name == profile.name);
    connectedProfiles.remove(profile);
    connectingProfiles.remove(profile);
    errorMessages.remove(profile.name);
    await saveProfiles();
  }

  Future<void> toggleConnection(ProfileModel profile) async {
    errorMessages.remove(profile.name);
    if (connectedProfiles.contains(profile)) {
      connectedProfiles.remove(profile);
    } else {
      connectingProfiles.add(profile);
      try {
        await SessionManager.connect(profile);
        connectedProfiles.add(profile);
      } on Exception catch (e) {
        errorMessages[profile.name] = e.toString();
      } finally {
        connectingProfiles.remove(profile);
      }
    }
  }

  Future<void> createProfile({ProfileModel? profile}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: profile?.name ?? "");
    final urlController = TextEditingController(text: profile?.url ?? "");
    final realmController = TextEditingController(text: profile?.realm ?? "");
    final authidController = TextEditingController(text: profile?.authid ?? "");
    final secretController = TextEditingController(text: profile?.secret ?? "");
    bool isSecretHidden = true;

    final serializers = ["JSON", "MsgPack", "CBOR"];
    final authMethods = ["Anonymous", "Ticket", "WAMP-CRA", "CryptoSign"];

    var selectedSerializer = serializers.contains(profile?.serializer)
        ? profile?.serializer ?? serializers.first
        : serializers.first;
    var selectedAuthMethod = authMethods.contains(profile?.authmethod)
        ? profile?.authmethod ?? authMethods.first
        : authMethods.first;

    await Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(profile == null ? "Create Profile" : "Update Profile"),
            content: Form(
              key: formKey,
              child: SizedBox(
                width: 300,
                height: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "Name"),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return "Please enter a name";
                        }
                        if (profiles.any(
                          (p) => p.name == value && p.name != profile?.name,
                        )) {
                          return "Name already exists. Choose a different name.";
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: urlController,
                      decoration: const InputDecoration(labelText: "URL"),
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
                        obscureText: isSecretHidden,
                        // Hide the secret by default
                        decoration: InputDecoration(
                          labelText: "Secret",
                          suffixIcon: IconButton(
                            icon: Icon(
                              isSecretHidden
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                isSecretHidden = !isSecretHidden;
                              });
                            },
                          ),
                        ),
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
      barrierDismissible: false,
    );
  }
}
