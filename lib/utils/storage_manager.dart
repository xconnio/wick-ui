import "dart:convert";
import "dart:io";

import "package:flutter/foundation.dart" show kIsWeb;
import "package:ini/ini.dart";
import "package:path_provider/path_provider.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:wick_ui/app/data/models/profile_model.dart";

mixin StorageManager {
  static Future<void> saveProfiles(List<ProfileModel> profiles) async {
    if (kIsWeb) {
      // For web: save profiles as JSON in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final profilesList = profiles.map((p) => p.toJson()).toList();
      await prefs.setString("profiles", jsonEncode(profilesList));
    } else {
      // For mobile/desktop: save profiles in an .ini file
      final directory = await getApplicationDocumentsDirectory();
      final file = File("${directory.path}/profiles.ini");
      var config = Config();

      // Add each profile to the .ini file
      for (final profile in profiles) {
        var section = profile.name;
        config
          ..addSection(section)
          ..set(section, "name", profile.name)
          ..set(section, "url", profile.url)
          ..set(section, "realm", profile.realm)
          ..set(section, "serializer", profile.serializer)
          ..set(section, "authmethod", profile.authmethod)
          ..set(section, "secret", profile.secret)
          ..set(section, "authid", profile.authid);
      }

      // Save the .ini file
      await file.writeAsString(config.toString());
    }
  }

  static Future<List<ProfileModel>> loadProfiles() async {
    if (kIsWeb) {
      // For web: load profiles from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final profilesString = prefs.getString("profiles");
      if (profilesString != null) {
        final profilesJson = jsonDecode(profilesString) as List;
        return profilesJson.map((profileJson) => ProfileModel.fromJson(profileJson)).toList();
      }
    } else {
      // For mobile/desktop: load profiles from an .ini file
      final directory = await getApplicationDocumentsDirectory();
      final file = File("${directory.path}/profiles.ini");
      if (file.existsSync()) {
        var config = Config.fromStrings(await file.readAsLines());
        return config.sections().map((section) {
          return ProfileModel(
            name: config.get(section, "name") ?? "",
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
