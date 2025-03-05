import "package:wick_ui/app/data/models/authenticator/authenticator_base.dart";

class AnonymousConfig extends AuthenticatorBase {
  AnonymousConfig({
    required super.authid,
    required super.realm,
    required super.role,
  });

  factory AnonymousConfig.fromJson(Map<String, dynamic> json) {
    return AnonymousConfig(
      authid: json["authid"],
      realm: json["realm"],
      role: json["role"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "authid": authid,
      "realm": realm,
      "role": role,
    };
  }
}
