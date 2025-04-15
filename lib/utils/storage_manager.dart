import "dart:convert";
import "dart:io";

import "package:flutter/foundation.dart" show kIsWeb;
import "package:ini/ini.dart";
import "package:path_provider/path_provider.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:wick_ui/app/data/models/client_model.dart";

mixin StorageManager {
  static Future<String> _getConfigFilePath() async {
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      final homeDir = Platform.environment["HOME"] ?? Platform.environment["USERPROFILE"];
      if (homeDir == null) {
        throw Exception("Unable to determine home directory");
      }
      final configDir = Directory("$homeDir/.wick");
      if (!configDir.existsSync()) {
        configDir.createSync(recursive: true);
      }
      return "${configDir.path}/config";
    } else {
      final directory = await getApplicationDocumentsDirectory();
      return "${directory.path}/clients.ini";
    }
  }

  static Future<void> saveClients(List<ClientModel> clients) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final clientsList = clients.map((p) => p.toJson()).toList();
      await prefs.setString("clients", jsonEncode(clientsList));
    } else {
      final filePath = await _getConfigFilePath();
      final file = File(filePath);
      var config = Config();

      for (final client in clients) {
        var section = "client ${client.name}";
        config
          ..addSection(section)
          ..set(section, "uri", client.uri)
          ..set(section, "realm", client.realm)
          ..set(section, "serializer", client.serializer)
          ..set(section, "authmethod", client.authmethod)
          ..set(section, "secret", client.secret)
          ..set(section, "authid", client.authid);
      }

      final configString = config.toString();
      final formattedConfigString = configString
          .replaceAllMapped(
            RegExp(r"(\[.*?\])"),
            (match) => "\n${match.group(0)}",
          )
          .trim();

      await file.writeAsString(formattedConfigString);
    }
  }

  static Future<List<ClientModel>> loadClients() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final clientsString = prefs.getString("clients");
      if (clientsString != null) {
        final clientsJson = jsonDecode(clientsString) as List;
        return clientsJson.map((clientJson) => ClientModel.fromJson(clientJson)).toList();
      }
    } else {
      final filePath = await _getConfigFilePath();
      final file = File(filePath);
      if (file.existsSync()) {
        var config = Config.fromStrings(await file.readAsLines());
        return config.sections().map((section) {
          return ClientModel(
            name: section.replaceFirst("client ", ""),
            uri: config.get(section, "uri") ?? "",
            realm: config.get(section, "realm") ?? "",
            serializer: config.get(section, "serializer") ?? "",
            authmethod: config.get(section, "authmethod") ?? "",
            secret: config.get(section, "secret") ?? "",
            authid: config.get(section, "authid") ?? "",
          );
        }).toList();
      }
    }
    return [];
  }
}
