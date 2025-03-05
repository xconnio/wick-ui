class RealmConfig {
  RealmConfig({required this.name});

  factory RealmConfig.fromJson(Map<String, dynamic> json) {
    return RealmConfig(
      name: json["name"],
    );
  }

  final String name;

  Map<String, dynamic> toJson() {
    return {
      "name": name,
    };
  }
}
