class ProfileModel {
  final String name;
  final String url;
  final String realm;
  final String serializer;
  final String authid;
  final String authmethod;
  final String secret;

  ProfileModel({
    required this.name,
    required this.url,
    required this.realm,
    required this.serializer,
    required this.authid,
    required this.authmethod,
    required this.secret,
  });

  // Convert a ProfileModel into a Map. The keys must correspond to the names of the attributes.
  Map<String, dynamic> toJson() => {
        "name": name,
        "url": url,
        "realm": realm,
        "serializer": serializer,
        "authid": authid,
        "authmethod": authmethod,
        "secret": secret,
      };

  // Convert a Map into a ProfileModel.
  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
        name: json["name"],
        url: json["url"],
        realm: json["realm"],
        serializer: json["serializer"],
        authid: json["authid"],
        authmethod: json["authmethod"],
        secret: json["secret"],
      );
}
