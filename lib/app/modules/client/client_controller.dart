import "dart:developer";
import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:wick_ui/app/data/models/client_model.dart";
import "package:wick_ui/utils/session_manager.dart";
import "package:wick_ui/utils/state_manager.dart";
import "package:wick_ui/utils/storage_manager.dart";

class ClientController extends GetxController with StateManager, SessionManager {
  RxList<ClientModel> clients = <ClientModel>[].obs;
  RxList<ClientModel> connectingClient = <ClientModel>[].obs;
  RxMap<String, String> errorMessages = <String, String>{}.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    log("ClientController: onInit called");
    await initializeState();
    await loadClients();
    await restoreSessions(clients);
  }

  Future<void> saveClients() async {
    await StorageManager.saveClients(clients.toList());
    log("ClientController: Saved Clients");
  }

  Future<void> loadClients() async {
    clients.assignAll(await StorageManager.loadClients());
    log("ClientController: Loaded ${clients.length} clients");
  }

  Future<void> addClient(ClientModel client) async {
    clients.add(client);
    await saveClients();
    log("ClientController: Added client '${client.name}'");
  }

  Future<void> updateClient(ClientModel updatedClient) async {
    int index = clients.indexWhere((p) => p.name == updatedClient.name);
    if (index != -1) {
      clients[index] = updatedClient;
      await saveClients();
      log("ClientController: Updated client '${updatedClient.name}'");
    }
  }

  Future<void> deleteClient(ClientModel client) async {
    clients.removeWhere((p) => p.name == client.name);
    if (isConnected(client)) {
      await disconnect(client);
    }
    connectingClient.remove(client);
    errorMessages.remove(client.name);
    await saveClients();
    await saveClientState();
    log("ClientController: Deleted client '${client.name}'");
  }

  Future<void> toggleConnection(ClientModel client) async {
    errorMessages.remove(client.name);

    if (isConnected(client)) {
      await disconnect(client);
      return;
    }

    connectingClient.add(client);
    update();

    try {
      await connect(client);
      clientSessions[client.name] = true;
      await saveClientState();
    } on Exception catch (e) {
      final errorMsg = _processConnectionError(e);
      errorMessages[client.name] = errorMsg;
      clientSessions[client.name] = false;
      await saveClientState();
    } finally {
      connectingClient.remove(client);
      update();
    }
  }

  String _processConnectionError(error) {
    final errorStr = error.toString();

    if (errorStr.contains("Connection refused")) {
      return "Connection refused";
    } else if (errorStr.contains("wamp.error.no_such_realm")) {
      return "No such realm";
    } else if (errorStr.contains("WebSocketChannelException")) {
      return "Failed host lookup: Name or service not known";
    } else if (errorStr.contains("wamp.error.authentication_failed")) {
      return "Authentication Failed";
    } else if (errorStr.contains("timed out")) {
      return "Connection timeout";
    }

    return "Connection failed";
  }

  Future<void> createClient({ClientModel? client}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: client?.name ?? "");
    final uriController = TextEditingController(text: client?.uri ?? "");
    final realmController = TextEditingController(text: client?.realm ?? "");
    final authidController = TextEditingController(text: client?.authid ?? "");
    final secretController = TextEditingController(text: client?.secret ?? "");

    bool obscurePassword = true;

    final serializers = ["JSON", "MSGPACK", "CBOR"];
    final authMethods = ["Anonymous", "Ticket", "WAMP-CRA", "CryptoSign"];

    var selectedSerializer =
        serializers.contains(client?.serializer) ? client?.serializer ?? serializers.first : serializers.first;
    var selectedAuthMethod =
        authMethods.contains(client?.authmethod) ? client?.authmethod ?? authMethods.first : authMethods.first;

    await Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          bool isDesktop = MediaQuery.of(context).size.width > 600;
          double dialogWidth =
              isDesktop ? MediaQuery.of(context).size.width * 0.6 : MediaQuery.of(context).size.width * 0.9;

          return AlertDialog(
            title: Text(client == null ? "Create Client" : "Update Client"),
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
                          labelText: "Client name",
                          context: context,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return "please enter a name";
                            }
                            if (clients.any(
                              (p) => p.name == value && p.name != client?.name,
                            )) {
                              return "client name already exists. choose a different name.";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: _responsiveSpacing(context)),
                        if (isDesktop)
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: _buildTextField(
                                  controller: uriController,
                                  labelText: "URI",
                                  context: context,
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      return "please enter a URI";
                                    }
                                    if (!value.startsWith("ws://") && !value.startsWith("wss://")) {
                                      return "URI must start with ws:// or wss://";
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: _buildTextField(
                                      controller: uriController,
                                      labelText: "URI",
                                      context: context,
                                      validator: (value) {
                                        if (value!.isEmpty) {
                                          return "please enter a URI";
                                        }
                                        if (!value.startsWith("ws://") && !value.startsWith("wss://")) {
                                          return "URI must start with ws:// or wss://";
                                        }
                                        return null;
                                      },
                                    ),
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
                            labelText: "Realm",
                            context: context,
                            validator: (value) => value!.isEmpty ? "please enter a realm" : null,
                          ),
                          fieldTwo: DropdownButtonFormField<String>(
                            value: selectedSerializer,
                            decoration: InputDecoration(
                              labelText: "Serializer",
                              isDense: true,
                              contentPadding: _responsivePadding(context),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: serializers.map((serializer) {
                              return DropdownMenuItem<String>(
                                value: serializer,
                                child: Text(
                                  serializer,
                                  style: const TextStyle(fontSize: 14),
                                ),
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
                            labelText: "Authid",
                            context: context,
                            validator: (value) {
                              if (selectedAuthMethod != "Anonymous" && (value == null || value.isEmpty)) {
                                return "please enter an authid";
                              }
                              return null;
                            },
                          ),
                          fieldTwo: DropdownButtonFormField<String>(
                            value: selectedAuthMethod,
                            decoration: InputDecoration(
                              labelText: "Auth method",
                              isDense: true,
                              contentPadding: _responsivePadding(context),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: authMethods.map((authMethod) {
                              return DropdownMenuItem<String>(
                                value: authMethod,
                                child: Text(
                                  authMethod,
                                  style: const TextStyle(fontSize: 14),
                                ),
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
                        if (selectedAuthMethod != "Anonymous")
                          TextFormField(
                            controller: secretController,
                            decoration: InputDecoration(
                              labelText: _getSecretLabel(selectedAuthMethod),
                              isDense: true,
                              contentPadding: _responsivePadding(context),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscurePassword ? Icons.visibility_off : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    obscurePassword = !obscurePassword;
                                  });
                                },
                              ),
                            ),
                            obscureText: obscurePassword,
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
                    final newClient = ClientModel(
                      name: nameController.text,
                      uri: uriController.text,
                      realm: realmController.text,
                      serializer: selectedSerializer,
                      authid: authidController.text,
                      authmethod: selectedAuthMethod,
                      secret: secretController.text,
                    );
                    if (client == null) {
                      await addClient(newClient);
                      await toggleConnection(newClient);
                    } else {
                      await updateClient(newClient);
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
    );
  }

  String _getSecretLabel(String authMethod) {
    switch (authMethod) {
      case "Ticket":
        return "Ticket";
      case "WAMP-CRA":
        return "Secret";
      case "CryptoSign":
        return "Private key";
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
