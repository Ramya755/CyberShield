import 'package:realm/realm.dart';

part 'scam_detection_realm.realm.dart';

@RealmModel()
class _ScamDetectionRealm {
  @PrimaryKey()
  late String id;

  late String appName;
  late String sender;
  late String message;
  late DateTime receivedAt;
  late int riskScore;
  late bool isScam;

  // Prepared for future MongoDB sync pipeline.
  late bool isSynced;
}
