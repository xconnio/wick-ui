import "package:wick_ui/app/data/models/authenticator/authenticator_config.dart";
import "package:wick_ui/app/data/models/router/realm_config.dart";
import "package:wick_ui/app/data/models/router/tranport_config.dart";

class RouterConfigModel {
  RouterConfigModel({
    required this.version, // Initialize in the constructor
    required this.realms,
    required this.transports,
    required this.authenticators,
  });

  // Add a factory constructor for JSON deserialization if needed
  factory RouterConfigModel.fromJson(Map<String, dynamic> json) {
    return RouterConfigModel(
      version: json["version"] ?? "1", // Provide a default value
      realms: (json["realms"] as List).map((realm) => RealmConfig.fromJson(realm)).toList(),
      transports: (json["transports"] as List).map((transport) => TransportConfig.fromJson(transport)).toList(),
      authenticators: AuthenticatorConfig.fromJson(json["authenticators"]),
    );
  }
  String version; // Remove 'late' keyword
  List<RealmConfig> realms;
  List<TransportConfig> transports;
  AuthenticatorConfig authenticators;

  // Add a toJson method for serialization
  Map<String, dynamic> toJson() {
    return {
      "version": version,
      "realms": realms.map((realm) => realm.toJson()).toList(),
      "transports": transports.map((transport) => transport.toJson()).toList(),
      "authenticators": authenticators.toJson(),
    };
  }
}
