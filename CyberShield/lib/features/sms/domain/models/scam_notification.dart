/// Unified scam notification model used by local notifications, popup UI,
/// and future persistence layers (Realm/MongoDB sync).
class ScamNotification {
  final String appName;
  final String sender;
  final String message;
  final DateTime receivedAt;
  final int riskScore;
  final bool isScam;

  const ScamNotification({
    required this.appName,
    required this.sender,
    required this.message,
    required this.receivedAt,
    required this.riskScore,
    required this.isScam,
  });

  /// Stable id for dedupe/history (safe to use for offline-first storage keys).
  String get eventId =>
      '${receivedAt.millisecondsSinceEpoch}|$appName|$sender|$message|$riskScore|$isScam';

  Map<String, dynamic> toJson() {
    return {
      'appName': appName,
      'sender': sender,
      'message': message,
      'receivedAt': receivedAt.millisecondsSinceEpoch,
      'riskScore': riskScore,
      'isScam': isScam,
    };
  }

  factory ScamNotification.fromJson(Map<String, dynamic> json) {
    final millis = _asInt(json['receivedAt']);
    return ScamNotification(
      appName: (json['appName'] ?? '').toString(),
      sender: (json['sender'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      receivedAt: DateTime.fromMillisecondsSinceEpoch(millis),
      riskScore: _asInt(json['riskScore']),
      isScam: _asBool(json['isScam']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    final normalized = (value?.toString() ?? '').toLowerCase();
    return normalized == 'true' || normalized == '1';
  }
}
