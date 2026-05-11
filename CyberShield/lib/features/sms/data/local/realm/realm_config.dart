import 'package:path_provider/path_provider.dart';
import 'package:realm/realm.dart';

import 'package:path/path.dart' as path;

import 'realm_models/scam_detection_realm.dart';

class RealmConfig {
  const RealmConfig._();

  static const String fileName = 'scam_detector.realm';
  static const int schemaVersion = 1;

  static Future<Configuration> localConfig() async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = path.join(directory.path, fileName);

    return Configuration.local(
      [ScamDetectionRealm.schema],
      schemaVersion: schemaVersion,
      path: filePath,
    );
  }
}
