abstract class AuthenticatorBase {
  AuthenticatorBase({
    required this.authid,
    required this.realm,
    required this.role,
  });
  final String authid;
  final String realm;
  final String role;
}
