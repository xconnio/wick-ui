import "package:wick_ui/app/data/models/authenticator/authenticator_base.dart";

class CryptoSignConfig extends AuthenticatorBase {
  CryptoSignConfig({
    required super.authid,
    required super.realm,
    required super.role,
    required this.authorizedKeys,
  });

  factory CryptoSignConfig.fromJson(Map<String, dynamic> json) {
    return CryptoSignConfig(
      authid: json["authid"],
      realm: json["realm"],
      role: json["role"],
      authorizedKeys: List<String>.from(json["authorized_keys"]),
    );
  }
  final List<String> authorizedKeys;

  Map<String, dynamic> toJson() {
    return {
      "authid": authid,
      "realm": realm,
      "role": role,
      "authorized_keys": authorizedKeys,
    };
  }
}
