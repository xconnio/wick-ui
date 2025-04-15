class ClientModel {
  ClientModel({
    required this.name,
    required this.uri,
    required this.realm,
    required this.serializer,
    required this.authid,
    required this.authmethod,
    required this.secret,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) => ClientModel(
        name: json["name"],
        uri: json["uri"],
        realm: json["realm"],
        serializer: json["serializer"],
        authid: json["authid"],
        authmethod: json["authmethod"],
        secret: json["secret"],
      );

  final String name;
  final String uri;
  final String realm;
  final String serializer;
  final String authid;
  final String authmethod;
  final String secret;

  Map<String, dynamic> toJson() => {
        "name": name,
        "uri": uri,
        "realm": realm,
        "serializer": serializer,
        "authid": authid,
        "authmethod": authmethod,
        "secret": secret,
      };
}
