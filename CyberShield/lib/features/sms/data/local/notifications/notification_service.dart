import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:scam_detector/core/shared/navigation.dart';
import 'package:scam_detector/features/sms/domain/models/scam_notification.dart';
import 'package:scam_detector/core/widgets/scam_popup.dart';
import 'package:scam_detector/core/shared/app_config.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  // Background isolate callback (Android/iOS). UI actions are not attempted here.
  // Foreground flow and app-launch flow are handled in NotificationService.initialize().
}

/// NotificationService handles showing system notifications and
/// responding to taps. The payload is encoded as JSON and contains
/// the full scam notification data so the app can display a dialog
/// after the user taps the notification.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Track payload ids that have already been shown to prevent duplicates.
  static final LinkedHashMap<String, DateTime> _shownPayloadIds =
      LinkedHashMap<String, DateTime>();
  static bool _initialized = false;
  static bool _isDialogVisible = false;
  static const int _maxShownPayloads = 200;
  static const Duration _payloadRetention = Duration(hours: 24);

  // Channel constants are kept centralized for future platform expansion.
  static const String _channelId = AppConfig.notificationChannelId;
  static const String _channelName = AppConfig.notificationChannelName;
  static const String _channelDescription =
      AppConfig.notificationChannelDescription;

  /// Initialize the local notifications plugin and register tap handler.
  static Future<void> initialize() async {
    if (_initialized) return;

    debugPrint('Notification initialize started');

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (kDebugMode) {
          debugPrint('Notification tapped');
          debugPrint('Payload: ${response.payload}');
        }

        // Handle tap in a separate async flow so we can await navigation.
        unawaited(_handleNotificationResponse(response.payload));
      },
    );

    // Handle cold start: app opened by tapping a notification while terminated.
    final launchDetails =
        await _notificationsPlugin.getNotificationAppLaunchDetails();
    final launchedFromNotification =
        launchDetails?.didNotificationLaunchApp ?? false;
    if (launchedFromNotification) {
      final launchedPayload = launchDetails?.notificationResponse?.payload;
      unawaited(_handleNotificationResponse(launchedPayload));
    }

    // Request permissions on Android 13+ devices if available.
    // For Android 13+ we request runtime notification permission using
    // the permission_handler package. This avoids relying on methods
    // that may not exist on the plugin API.
    try {
      final status = await Permission.notification.request();
      if (kDebugMode) {
        debugPrint('Notification permission status: $status');
      }
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
    }

    _initialized = true;
    debugPrint('Notification initialize completed');
  }

  /// Show a scam alert notification only.
  ///
  /// This method does not display any popup/dialog. Popup display is strictly
  /// tap-driven from [_handleNotificationResponse].
  static Future<void> showScamAlert({
    required ScamNotification notification,
  }) async {
    final int id = notification.receivedAt.millisecondsSinceEpoch;

    final Map<String, dynamic> payload =
        notification.toJson()..['id'] = notification.eventId;

    final String encoded = jsonEncode(payload);

    if (kDebugMode) {
      debugPrint('Showing notification with payload: $encoded');
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      id ~/ 1000,
      'Scam Alert from ${notification.appName} 🚨',
      '${notification.sender}: ${notification.message}',
      notificationDetails,
      payload: encoded,
    );

    if (kDebugMode) {
      debugPrint('Notification show function completed');
    }
  }

  // Internal: handle notification tap payload, navigate to HomeShell and show dialog.
  static Future<void> _handleNotificationResponse(String? payload) async {
    if (payload == null || payload.isEmpty) return;

    Map<String, dynamic> data;
    try {
      data = jsonDecode(payload) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Failed to decode notification payload: $e');
      return;
    }

    final String id = (data['id'] ?? '').toString();
    if (id.isEmpty) return;

    // Avoid showing the same dialog more than once.
    if (_shownPayloadIds.containsKey(id)) {
      debugPrint('Payload $id already shown, skipping');
      return;
    }

    if (_isDialogVisible) {
      debugPrint('A scam dialog is already visible, skipping duplicate');
      return;
    }

    final scam = ScamNotification.fromJson(data);

    // Popup should only be shown for scam-positive payloads.
    if (!scam.isScam) {
      debugPrint('Tapped payload isScam=false, popup suppressed');
      return;
    }

    // Ensure the app returns to the root HomeShell view before
    // presenting the scam popup above that screen.
    try {
      // If navigator is not ready yet (app launching), wait briefly.
      const timeout = Duration(seconds: 5);
      final end = DateTime.now().add(timeout);

      while (navigatorKey.currentState == null &&
          DateTime.now().isBefore(end)) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      final navState = navigatorKey.currentState;
      if (navState == null) {
        debugPrint('Navigator still null after waiting, cannot show popup');
        return;
      }

      // Pop to root so the Home UI becomes visible (HomeShell is the
      // root widget). This avoids importing app widgets here and
      // prevents a circular import.
      navState.popUntil((route) => route.isFirst);

      // Wait a frame to ensure HomeShell widgets are built.
      await Future.delayed(const Duration(milliseconds: 300));

      if (!navState.mounted) {
        debugPrint('Navigator state unmounted, aborting popup');
        return;
      }

      final BuildContext ctx = navState.context;
      if (!ctx.mounted) {
        debugPrint('Context still null after navigation, aborting popup');
        return;
      }

      // Mark as shown before presenting to avoid race conditions.
      _shownPayloadIds[id] = DateTime.now();
      _pruneShownPayloads();
      _isDialogVisible = true;

      // Show the reusable popup above HomeShell.
      await ScamPopup.show(context: ctx, notification: scam);
      _isDialogVisible = false;
    } catch (e) {
      _isDialogVisible = false;
      debugPrint('Error handling notification tap: $e');
    }
  }

  static void _pruneShownPayloads() {
    final cutoff = DateTime.now().subtract(_payloadRetention);
    _shownPayloadIds.removeWhere((_, timestamp) => timestamp.isBefore(cutoff));

    while (_shownPayloadIds.length > _maxShownPayloads) {
      _shownPayloadIds.remove(_shownPayloadIds.keys.first);
    }
  }
}
