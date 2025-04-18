class TransportConfig {
  TransportConfig({
    required this.port,
    this.type = "websocket",
    this.serializers = const ["json"],
  }) {
    if (port < 0 || port > 65535) {
      throw ArgumentError("Port must be between 0 and 65535");
    }
    if (serializers.isEmpty) {
      throw ArgumentError("At least one serializer is required");
    }
  }

  factory TransportConfig.fromJson(Map<String, dynamic> json) {
    return TransportConfig(
      type: json["type"],
      port: json["port"],
      serializers: List<String>.from(json["serializers"]),
    );
  }

  final String type;
  final int port;
  final List<String> serializers;

  Map<String, dynamic> toJson() {
    return {
      "type": type,
      "port": port,
      "serializers": serializers,
    };
  }
}
