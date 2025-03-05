import "package:wick_ui/app/data/models/authenticator/authenticator_base.dart";

class TicketConfig extends AuthenticatorBase {
  TicketConfig({
    required super.authid,
    required super.realm,
    required super.role,
    required this.ticket,
  });

  factory TicketConfig.fromJson(Map<String, dynamic> json) {
    return TicketConfig(
      authid: json["authid"],
      realm: json["realm"],
      role: json["role"],
      ticket: json["ticket"],
    );
  }

  final String ticket;

  Map<String, dynamic> toJson() {
    return {
      "authid": authid,
      "realm": realm,
      "role": role,
      "ticket": ticket,
    };
  }
}
