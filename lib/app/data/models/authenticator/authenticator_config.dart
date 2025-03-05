import "package:wick_ui/app/data/models/authenticator/anonymous_config.dart";
import "package:wick_ui/app/data/models/authenticator/cryptosign_config.dart";
import "package:wick_ui/app/data/models/authenticator/ticket_config.dart";
import "package:wick_ui/app/data/models/authenticator/wamp_cra_config.dart";

class AuthenticatorConfig {
  AuthenticatorConfig({
    this.cryptosign = const [],
    this.wampcra = const [],
    this.ticket = const [],
    this.anonymous = const [],
  });

  factory AuthenticatorConfig.fromJson(Map<String, dynamic> json) {
    return AuthenticatorConfig(
      cryptosign: List<CryptoSignConfig>.from(
        (json["cryptosign"] as List<dynamic>).map((x) => CryptoSignConfig.fromJson(x)),
      ),
      wampcra: List<WampCraConfig>.from(
        (json["wampcra"] as List<dynamic>).map((x) => WampCraConfig.fromJson(x)),
      ),
      ticket: List<TicketConfig>.from(
        (json["ticket"] as List<dynamic>).map((x) => TicketConfig.fromJson(x)),
      ),
      anonymous: List<AnonymousConfig>.from(
        (json["anonymous"] as List<dynamic>).map((x) => AnonymousConfig.fromJson(x)),
      ),
    );
  }

  final List<CryptoSignConfig> cryptosign;
  final List<WampCraConfig> wampcra;
  final List<TicketConfig> ticket;
  final List<AnonymousConfig> anonymous;

  Map<String, dynamic> toJson() {
    return {
      "cryptosign": cryptosign.map((x) => x.toJson()).toList(),
      "wampcra": wampcra.map((x) => x.toJson()).toList(),
      "ticket": ticket.map((x) => x.toJson()).toList(),
      "anonymous": anonymous.map((x) => x.toJson()).toList(),
    };
  }
}
