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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is RealmConfig && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}
