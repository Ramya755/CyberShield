import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/notification_event.dart';

/// Service for listening to real-time notifications from Android NotificationListenerService.
///
/// This service bridges the native Android notification listener with Flutter,
/// receiving notifications from: WhatsApp, Gmail, Messenger, Messages, and Outlook.
///
/// Usage:
/// ```dart
/// final service = NotificationListenerService();
/// await service.startListening();
/// service.stream.listen((event) {
///   debugPrint('Captured: ${event.appName} - ${event.sender}: ${event.message}');
/// });
/// ```
class NotificationListenerService {
  static const EventChannel _eventChannel = EventChannel(
    'scam_detector/notification_listener',
  );
  static const MethodChannel _methodChannel = MethodChannel(
    'scam_detector/notification_listener_settings',
  );

  StreamSubscription<dynamic>? _subscription;
  final StreamController<NotificationData> _controller =
      StreamController<NotificationData>.broadcast();

  Stream<NotificationData> get stream => _controller.stream;

  /// Start listening to notifications from Android NotificationListenerService.
  ///
  /// Safe to call multiple times; subsequent calls are no-op.
  Future<void> startListening() async {
    if (_subscription != null) {
      debugPrint(
        '[NotificationListenerService] Already listening, skipping start.',
      );
      return;
    }

    debugPrint('[NotificationListenerService] Starting listener...');

    _subscription = _eventChannel.receiveBroadcastStream().listen(
      (event) {
        if (event is! Map<dynamic, dynamic>) {
          debugPrint(
            '[NotificationListenerService] Ignoring non-map event: $event',
          );
          return;
        }

        try {
          final notification = NotificationData.fromMap(event);
          if (kDebugMode) {
            debugPrint('[NotificationListenerService] Captured: $notification');
          }
          _controller.add(notification);
        } catch (error, stackTrace) {
          debugPrint('[NotificationListenerService] Parse error: $error');
          if (kDebugMode) {
            debugPrint('$stackTrace');
          }
        }
      },
      onError: (error, stackTrace) {
        debugPrint('[NotificationListenerService] Stream error: $error');
        if (kDebugMode) {
          debugPrint('$stackTrace');
        }
      },
    );

    debugPrint('[NotificationListenerService] Listener started successfully.');
  }

  /// Stop listening to notifications.
  Future<void> stopListening() async {
    debugPrint('[NotificationListenerService] Stopping listener...');
    await _subscription?.cancel();
    _subscription = null;
    debugPrint('[NotificationListenerService] Listener stopped.');
  }

  /// Check if notification listener permission is granted by user.
  Future<bool> isPermissionEnabled() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'isNotificationListenerEnabled',
      );
      final enabled = result ?? false;
      debugPrint('[NotificationListenerService] Permission enabled: $enabled');
      return enabled;
    } catch (e) {
      debugPrint('[NotificationListenerService] Error checking permission: $e');
      return false;
    }
  }

  /// Open Android notification access settings to allow user to enable permission.
  Future<void> openNotificationAccessSettings() async {
    try {
      debugPrint(
        '[NotificationListenerService] Opening notification access settings...',
      );
      await _methodChannel.invokeMethod<void>('openNotificationAccessSettings');
    } catch (e) {
      debugPrint('[NotificationListenerService] Error opening settings: $e');
    }
  }

  /// Clean up resources.
  void dispose() {
    debugPrint('[NotificationListenerService] Disposing...');
    unawaited(_subscription?.cancel() ?? Future<void>.value());
    _controller.close();
  }
}
