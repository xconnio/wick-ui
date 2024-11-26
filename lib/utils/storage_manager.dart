import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ini/ini.dart';
import '../app/data/models/profile_model.dart';

class StorageManager {
  static Future<void> saveProfiles(List<ProfileModel> profiles) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final profilesList = profiles.map((p) => p.toJson()).toList();
      await prefs.setString('profiles', jsonEncode(profilesList));
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/profiles.ini');
      var config = Config();

      profiles.forEach((profile) {
        config.addSection(profile.authid);
        config.set(profile.authid, 'url', profile.url);
        config.set(profile.authid, 'realm', profile.realm);
        config.set(profile.authid, 'serializer', profile.serializer);
        config.set(profile.authid, 'authmethod', profile.authmethod);
        config.set(profile.authid, 'secret', profile.secret);
      });

      await file.writeAsString(config.toString());
    }
  }

  static Future<List<ProfileModel>> loadProfiles() async {
    List<ProfileModel> profiles = [];

    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final profilesString = prefs.getString('profiles');
      if (profilesString != null) {
        final profilesJson = jsonDecode(profilesString) as List;
        profiles = profilesJson
            .map((profileJson) => ProfileModel.fromJson(profileJson))
            .toList();
      }
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/profiles.ini');
      if (await file.exists()) {
        var config = Config.fromStrings(await file.readAsLines());
        for (var section in config.sections()) {
          profiles.add(ProfileModel(
            url: config.get(section, 'url') ?? '',
            realm: config.get(section, 'realm') ?? '',
            serializer: config.get(section, 'serializer') ?? '',
            authid: section,
            authmethod: config.get(section, 'authmethod') ?? '',
            secret: config.get(section, 'secret') ?? '',
          ));
        }
      }
    }

    return profiles;
  }
}
