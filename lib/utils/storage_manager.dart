import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ini/ini.dart';
import '../app/data/models/profile_model.dart';

mixin StorageManager {
  static Future<void> saveProfiles(List<ProfileModel> profiles) async {
    if (kIsWeb) {
      // For web: save profiles as JSON in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final profilesList = profiles.map((p) => p.toJson()).toList();
      await prefs.setString('profiles', jsonEncode(profilesList));
    } else {
      // For mobile/desktop: save profiles in an .ini file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/profiles.ini');
      var config = Config();

      // Add each profile to the .ini file
      for (var profile in profiles) {
        var section = profile.name;
        config.addSection(section);
        config.set(section, 'name', profile.name);
        config.set(section, 'url', profile.url);
        config.set(section, 'realm', profile.realm);
        config.set(section, 'serializer', profile.serializer);
        config.set(section, 'authmethod', profile.authmethod);
        config.set(section, 'secret', profile.secret);
        config.set(section, 'authid', profile.authid);
      }

      // Save the .ini file
      await file.writeAsString(config.toString());
    }
  }

  static Future<List<ProfileModel>> loadProfiles() async {
    if (kIsWeb) {
      // For web: load profiles from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final profilesString = prefs.getString('profiles');
      if (profilesString != null) {
        final profilesJson = jsonDecode(profilesString) as List;
        return profilesJson
            .map((profileJson) => ProfileModel.fromJson(profileJson))
            .toList();
      }
    } else {
      // For mobile/desktop: load profiles from an .ini file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/profiles.ini');
      if (await file.exists()) {
        var config = Config.fromStrings(await file.readAsLines());
        return config.sections().map((section) {
          return ProfileModel(
            name: config.get(section, 'name') ?? '',
            url: config.get(section, 'url') ?? '',
            realm: config.get(section, 'realm') ?? '',
            serializer: config.get(section, 'serializer') ?? '',
            authmethod: config.get(section, 'authmethod') ?? '',
            secret: config.get(section, 'secret') ?? '',
            authid: config.get(section, 'authid') ?? '',
          );
        }).toList();
      }
    }
    return [];
  }
}
