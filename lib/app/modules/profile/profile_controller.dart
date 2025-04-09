import "dart:developer";
import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:wick_ui/app/data/models/profile_model.dart";
import "package:wick_ui/utils/session_manager.dart";
import "package:wick_ui/utils/state_manager.dart";
import "package:wick_ui/utils/storage_manager.dart";

class ProfileController extends GetxController with StateManager, SessionManager {
  RxList<ProfileModel> profiles = <ProfileModel>[].obs;
  RxList<ProfileModel> connectingProfiles = <ProfileModel>[].obs;
  RxMap<String, String> errorMessages = <String, String>{}.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    log("ProfileController: onInit called");
    await initializeState();
    await loadProfiles();
    await restoreSessions(profiles);
  }

  Future<void> saveProfiles() async {
    await StorageManager.saveProfiles(profiles.toList());
    log("ProfileController: Saved profiles");
  }

  Future<void> loadProfiles() async {
    profiles.assignAll(await StorageManager.loadProfiles());
    log("ProfileController: Loaded ${profiles.length} profiles");
  }

  Future<void> addProfile(ProfileModel profile) async {
    profiles.add(profile);
    await saveProfiles();
    log("ProfileController: Added profile '${profile.name}'");
  }

  Future<void> updateProfile(ProfileModel updatedProfile) async {
    int index = profiles.indexWhere((p) => p.name == updatedProfile.name);
    if (index != -1) {
      profiles[index] = updatedProfile;
      await saveProfiles();
      log("ProfileController: Updated profile '${updatedProfile.name}'");
    }
  }

  Future<void> deleteProfile(ProfileModel profile) async {
    profiles.removeWhere((p) => p.name == profile.name);
    if (isConnected(profile)) {
      await disconnect(profile);
    }
    connectingProfiles.remove(profile);
    errorMessages.remove(profile.name);
    await saveProfiles();
    await saveProfileState();
    log("ProfileController: Deleted profile '${profile.name}'");
  }

  Future<void> toggleConnection(ProfileModel profile) async {
    errorMessages.remove(profile.name);
    if (isConnected(profile)) {
      await disconnect(profile);
      log("ProfileController: Disconnected '${profile.name}'");
    } else {
      connectingProfiles.add(profile);
      try {
        await connect(profile);
        log("ProfileController: Connected '${profile.name}'");
      } on Exception catch (e) {
        errorMessages[profile.name] = e.toString();
        profileSessions[profile.name] = false;
        await saveProfileState();
        log("ProfileController: Failed to connect '${profile.name}': $e");
      } finally {
        connectingProfiles.remove(profile);
        update();
      }
    }
  }

  Future<void> disconnectAllProfiles() async {
    log("ProfileController: Disconnecting all profiles");
    await clearAllSessions();
    log("ProfileController: All profiles disconnected and state cleared");
  }

  Future<void> createProfile({ProfileModel? profile}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: profile?.name ?? "");
    final uriController = TextEditingController(
      text: profile?.uri != null
          ? profile!.uri.replaceAll(RegExp("^(ws://|wss://)"), "").replaceAll(RegExp(r":\d+/ws$"), "")
          : "localhost",
    );
    final portController = TextEditingController(
      text: profile?.uri != null ? RegExp(r":(\d+)/ws$").firstMatch(profile!.uri)?.group(1) ?? "8080" : "8080",
    );
    final realmController = TextEditingController(text: profile?.realm ?? "");
    final authidController = TextEditingController(text: profile?.authid ?? "");
    final secretController = TextEditingController(text: profile?.secret ?? "");

    final serializers = ["json", "msgpack", "cbor"];
    final authMethods = ["anonymous", "ticket", "wamp-cra", "cryptoSign"];

    var selectedSerializer =
        serializers.contains(profile?.serializer) ? profile?.serializer ?? serializers.first : serializers.first;
    var selectedAuthMethod =
        authMethods.contains(profile?.authmethod) ? profile?.authmethod ?? authMethods.first : authMethods.first;
    var selectedProtocol = (profile?.uri.startsWith("wss://") ?? false) ? "wss://" : "ws://";

    await Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          bool isDesktop = MediaQuery.of(context).size.width > 600;
          double dialogWidth =
              isDesktop ? MediaQuery.of(context).size.width * 0.6 : MediaQuery.of(context).size.width * 0.9;

          return AlertDialog(
            title: Text(profile == null ? "Create Profile" : "Update Profile"),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: SizedBox(
                width: dialogWidth,
                height: MediaQuery.of(context).size.height * 0.6,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTextField(
                          controller: nameController,
                          labelText: "profile name",
                          context: context,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return "please enter a name";
                            }
                            if (profiles.any((p) => p.name == value && p.name != profile?.name)) {
                              return "profile name already exists. choose a different name.";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: _responsiveSpacing(context)),
                        if (isDesktop)
                          Row(
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Radio<String>(
                                    value: "ws://",
                                    groupValue: selectedProtocol,
                                    onChanged: (value) {
                                      setState(() {
                                        selectedProtocol = value!;
                                      });
                                    },
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  const Text("ws://"),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Radio<String>(
                                    value: "wss://",
                                    groupValue: selectedProtocol,
                                    onChanged: (value) {
                                      setState(() {
                                        selectedProtocol = value!;
                                      });
                                    },
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  const Text("wss://"),
                                ],
                              ),
                              Expanded(
                                flex: 3,
                                child: Padding(
                                  padding: EdgeInsets.only(left: _responsiveSpacing(context) / 2),
                                  child: _buildTextField(
                                    controller: uriController,
                                    labelText: "uri",
                                    context: context,
                                    validator: (value) {
                                      if (value!.isEmpty) {
                                        return "please enter a uri";
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ),
                              Flexible(
                                child: Padding(
                                  padding: EdgeInsets.only(left: _responsiveSpacing(context) / 2),
                                  child: SizedBox(
                                    width: 100,
                                    child: _buildTextField(
                                      controller: portController,
                                      labelText: "port",
                                      context: context,
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value!.isEmpty) {
                                          return "please enter a port";
                                        }
                                        if (int.tryParse(value) == null || int.parse(value) <= 0) {
                                          return "invalid port";
                                        }
                                        return null;
                                      },
                                      maxLength: 5,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: _responsiveSpacing(context) / 2),
                                child: const Text("/ws"),
                              ),
                            ],
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Radio<String>(
                                        value: "ws://",
                                        groupValue: selectedProtocol,
                                        onChanged: (value) {
                                          setState(() {
                                            selectedProtocol = value!;
                                          });
                                        },
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      const Text("ws://"),
                                    ],
                                  ),
                                  SizedBox(width: _responsiveSpacing(context)),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Radio<String>(
                                        value: "wss://",
                                        groupValue: selectedProtocol,
                                        onChanged: (value) {
                                          setState(() {
                                            selectedProtocol = value!;
                                          });
                                        },
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      const Text("wss://"),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: _responsiveSpacing(context) / 2),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: _buildTextField(
                                      controller: uriController,
                                      labelText: "uri",
                                      context: context,
                                      validator: (value) {
                                        if (value!.isEmpty) {
                                          return "please enter a uri";
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  SizedBox(width: _responsiveSpacing(context) / 2),
                                  Flexible(
                                    child: SizedBox(
                                      width: 100,
                                      child: _buildTextField(
                                        controller: portController,
                                        labelText: "port",
                                        context: context,
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (value!.isEmpty) {
                                            return "Please enter a port";
                                          }
                                          if (int.tryParse(value) == null || int.parse(value) <= 0) {
                                            return "invalid port";
                                          }
                                          return null;
                                        },
                                        maxLength: 5,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(left: _responsiveSpacing(context) / 2),
                                    child: const Text("/ws"),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        SizedBox(height: _responsiveSpacing(context)),
                        _buildResponsiveFields(
                          isDesktop: isDesktop,
                          context: context,
                          fieldOne: _buildTextField(
                            controller: realmController,
                            labelText: "realm",
                            context: context,
                            validator: (value) => value!.isEmpty ? "Please enter a realm" : null,
                          ),
                          fieldTwo: DropdownButtonFormField<String>(
                            value: selectedSerializer,
                            decoration: InputDecoration(
                              labelText: "serializer",
                              isDense: true,
                              contentPadding: _responsivePadding(context),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: serializers.map((serializer) {
                              return DropdownMenuItem<String>(
                                value: serializer,
                                child: Text(serializer, style: const TextStyle(fontSize: 14)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedSerializer = value!;
                              });
                            },
                            validator: (value) => value == null ? "please select a serializer" : null,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down),
                          ),
                        ),
                        SizedBox(height: _responsiveSpacing(context)),
                        _buildResponsiveFields(
                          isDesktop: isDesktop,
                          context: context,
                          fieldOne: _buildTextField(
                            controller: authidController,
                            labelText: "auth id",
                            context: context,
                            validator: (value) {
                              if (selectedAuthMethod != "anonymous" && (value == null || value.isEmpty)) {
                                return "please enter an auth id";
                              }
                              return null;
                            },
                          ),
                          fieldTwo: DropdownButtonFormField<String>(
                            value: selectedAuthMethod,
                            decoration: InputDecoration(
                              labelText: "auth method",
                              isDense: true,
                              contentPadding: _responsivePadding(context),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: authMethods.map((authMethod) {
                              return DropdownMenuItem<String>(
                                value: authMethod,
                                child: Text(authMethod, style: const TextStyle(fontSize: 14)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedAuthMethod = value!;
                                secretController.clear();
                              });
                            },
                            validator: (value) => value == null ? "please select an auth method" : null,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down),
                          ),
                        ),
                        SizedBox(height: _responsiveSpacing(context)),
                        if (selectedAuthMethod != "anonymous")
                          _buildTextField(
                            controller: secretController,
                            labelText: _getSecretLabel(selectedAuthMethod),
                            context: context,
                            validator: (value) {
                              if (value!.isEmpty) {
                                return "please enter ${_getSecretLabel(selectedAuthMethod).toLowerCase()}";
                              }
                              return null;
                            },
                          ),
                      ],
                    ),
                  ),
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
                    Get.back();
                    final fullUri = "$selectedProtocol${uriController.text}:${portController.text}/ws";
                    final newProfile = ProfileModel(
                      name: nameController.text,
                      uri: fullUri,
                      realm: realmController.text,
                      serializer: selectedSerializer,
                      authid: authidController.text,
                      authmethod: selectedAuthMethod,
                      secret: secretController.text,
                    );
                    if (profile == null) {
                      await addProfile(newProfile);
                      await toggleConnection(newProfile);
                    } else {
                      await updateProfile(newProfile);
                    }
                    update();
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

  Widget _buildResponsiveFields({
    required bool isDesktop,
    required BuildContext context,
    required Widget fieldOne,
    required Widget fieldTwo,
  }) {
    if (isDesktop) {
      return Row(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: _responsiveSpacing(context) / 2),
              child: fieldOne,
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: _responsiveSpacing(context) / 2),
              child: fieldTwo,
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          fieldOne,
          SizedBox(height: _responsiveSpacing(context)),
          fieldTwo,
        ],
      );
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required BuildContext context,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        isDense: true,
        contentPadding: _responsivePadding(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        counterText: maxLength != null ? "" : null,
      ),
      keyboardType: keyboardType,
      validator: validator,
      maxLength: maxLength,
      onChanged: (text) {
        controller.value = controller.value.copyWith(
          text: text.toLowerCase(),
          selection: TextSelection.collapsed(offset: text.length),
        );
      },
    );
  }

  String _getSecretLabel(String authMethod) {
    switch (authMethod) {
      case "ticket":
        return "ticket";
      case "wamp-cra":
        return "secret";
      case "cryptoSign":
        return "private key";
      default:
        return "";
    }
  }

  EdgeInsets _responsivePadding(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return EdgeInsets.symmetric(
      vertical: screenWidth > 600 ? 12.0 : 8.0,
      horizontal: screenWidth > 600 ? 16.0 : 12.0,
    );
  }

  double _responsiveSpacing(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return screenWidth > 600 ? 16.0 : 12.0;
  }
}
