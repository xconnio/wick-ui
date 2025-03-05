import "package:wick_ui/app/data/models/authenticator/authenticator_base.dart";

class WampCraConfig extends AuthenticatorBase {
  WampCraConfig({
    required super.authid,
    required super.realm,
    required super.role,
    required this.secret,
  });

  factory WampCraConfig.fromJson(Map<String, dynamic> json) {
    return WampCraConfig(
      authid: json["authid"],
      realm: json["realm"],
      role: json["role"],
      secret: json["secret"],
    );
  }
  final String secret;

  Map<String, dynamic> toJson() {
    return {
      "authid": authid,
      "realm": realm,
      "role": role,
      "secret": secret,
    };
  }
}
