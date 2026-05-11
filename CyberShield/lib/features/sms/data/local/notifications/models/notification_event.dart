/// Real-time notification captured from Android NotificationListenerService.
///
/// Supported apps:
/// - WhatsApp (com.whatsapp)
/// - Messenger (com.facebook.orca)
/// - Messages (com.google.android.apps.messaging)
///
/// All other notifications are ignored by the Android service layer.
class NotificationData {
  /// Exact Android package name (e.g., com.whatsapp)
  final String packageName;

  /// Human-readable app name (e.g., WhatsApp, Gmail, Messenger, Messages, Outlook)
  final String appName;

  /// Notification title/sender (e.g., contact name, email address, group name)
  final String sender;

  /// Notification message body text
  final String message;

  /// When the notification was posted (milliseconds since epoch)
  final DateTime receivedAt;

  const NotificationData({
    required this.packageName,
    required this.appName,
    required this.sender,
    required this.message,
    required this.receivedAt,
  });

  /// Parse notification from Android EventChannel map
  factory NotificationData.fromMap(Map<dynamic, dynamic> map) {
    return NotificationData(
      packageName: map['packageName'] as String? ?? '',
      appName: map['appName'] as String? ?? '',
      sender: map['sender'] as String? ?? '',
      message: map['message'] as String? ?? '',
      receivedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['timestamp'] as int?) ?? 0,
      ),
    );
  }

  /// Deduplication key for 10-second duplicate window
  String get dedupeKey {
    return '$packageName|$sender|$message';
  }

  @override
  String toString() =>
      'NotificationData('
      'app=$appName, '
      'sender=$sender, '
      'message=${message.length > 50 ? "${message.substring(0, 50)}..." : message}'
      ')';
}

/// Backward-compatible alias for existing call sites.
typedef NotificationEvent = NotificationData;
