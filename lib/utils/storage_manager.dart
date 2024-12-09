import "dart:convert";
import "dart:io";

import "package:flutter/foundation.dart" show kIsWeb;
import "package:ini/ini.dart";
import "package:path_provider/path_provider.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:wick_ui/app/data/models/profile_model.dart";

mixin StorageManager {
  static Future<String> _getConfigFilePath() async {
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      final homeDir =
          Platform.environment["HOME"] ?? Platform.environment["USERPROFILE"];
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
      return "${directory.path}/profiles.ini";
    }
  }

  static Future<void> saveProfiles(List<ProfileModel> profiles) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final profilesList = profiles.map((p) => p.toJson()).toList();
      await prefs.setString("profiles", jsonEncode(profilesList));
    } else {
      final filePath = await _getConfigFilePath();
      final file = File(filePath);
      var config = Config();

      for (final profile in profiles) {
        var section = "profile ${profile.name}";
        config
          ..addSection(section)
          ..set(section, "url", profile.url)
          ..set(section, "realm", profile.realm)
          ..set(section, "serializer", profile.serializer)
          ..set(section, "authmethod", profile.authmethod)
          ..set(section, "secret", profile.secret)
          ..set(section, "authid", profile.authid);
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

  static Future<List<ProfileModel>> loadProfiles() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final profilesString = prefs.getString("profiles");
      if (profilesString != null) {
        final profilesJson = jsonDecode(profilesString) as List;
        return profilesJson
            .map((profileJson) => ProfileModel.fromJson(profileJson))
            .toList();
      }
    } else {
      final filePath = await _getConfigFilePath();
      final file = File(filePath);
      if (file.existsSync()) {
        var config = Config.fromStrings(await file.readAsLines());
        return config.sections().map((section) {
          return ProfileModel(
            name: section.replaceFirst("profile ", ""),
            url: config.get(section, "url") ?? "",
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
