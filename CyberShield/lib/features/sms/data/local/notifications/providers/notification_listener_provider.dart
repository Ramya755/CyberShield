import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:scam_detector/features/sms/domain/repositories/scam_detection_repository.dart';
import 'package:scam_detector/features/sms/data/local/notifications/notification_service.dart';
import 'package:scam_detector/core/reliability/notification_queue_service.dart';
import 'package:scam_detector/core/settings/settings_service.dart';
import 'package:scam_detector/features/sms/data/local/tflite/models/prediction_result.dart';
import 'package:scam_detector/features/sms/data/local/tflite/prediction_service.dart';
import 'package:scam_detector/features/sms/domain/models/scam_notification.dart';

import '../models/notification_event.dart';
import '../services/notification_listener_service.dart';

/// Provider for managing notification listener state and lifecycle.
///
/// Responsibilities:
/// - Check and manage permission status
/// - Start/stop the listener service
/// - Handle incoming notification events
/// - Implement deduplication (10-second window)
/// - Log captured notifications
///
/// Usage:
/// ```dart
/// final provider = context.read<NotificationListenerProvider>();
/// await provider.initialize();
/// ```
class NotificationListenerProvider extends ChangeNotifier {
  final NotificationListenerService _service;
  final PredictionService _predictionService;
  final ScamDetectionRepository _realmRepository;
  late final NotificationQueueService _queueService;
  final SettingsService _settingsService;
  StreamSubscription<NotificationData>? _notificationSubscription;
  bool _permissionEnabled = false;
  bool _listening = false;
  bool _predictionReady = false;
  bool _initialized = false;
  bool _settingsListenerAttached = false;
  bool _lastProtectionEnabled = true;

  NotificationListenerProvider({
    NotificationListenerService? service,
    PredictionService? predictionService,
    required ScamDetectionRepository realmRepository,
    SettingsService? settingsService,
  }) : _service = service ?? NotificationListenerService(),
       _predictionService = predictionService ?? PredictionService(),
       _realmRepository = realmRepository,
       _settingsService = settingsService ?? SettingsService() {
    _queueService = NotificationQueueService(onProcess: _processEvent);
    debugPrint('[NotificationListenerProvider] Initialized');
  }

  bool get permissionEnabled => _permissionEnabled;
  bool get isListening => _listening;

  /// Initialize the provider by checking permissions and starting listener if enabled.
  Future<void> initialize() async {
    if (_initialized) return;

    debugPrint('[NotificationListenerProvider] Initializing...');

    try {
      await _settingsService.initialize();
      _attachSettingsListener();
      await _realmRepository.initialize();
      await _initializePredictionPipeline();

      _permissionEnabled = await _service.isPermissionEnabled();
      debugPrint(
        '[NotificationListenerProvider] Permission enabled: $_permissionEnabled',
      );
      notifyListeners();

      if (_permissionEnabled && _settingsService.settings.protectionEnabled) {
        debugPrint('[NotificationListenerProvider] Starting listener...');
        await _service.startListening();
        _listening = true;
        notifyListeners();

        // Listen to the service stream and handle each event
        await _attachStreamListener();
        debugPrint('[NotificationListenerProvider] Stream listener attached');
      } else {
        debugPrint('[NotificationListenerProvider] Permission not enabled yet');
      }

      _initialized = true;
    } catch (e) {
      debugPrint(
        '[NotificationListenerProvider] Error during initialization: $e',
      );
    }
  }

  Future<void> applyProtectionSetting() async {
    await _settingsService.initialize();
    _lastProtectionEnabled = _settingsService.settings.protectionEnabled;

    if (!_settingsService.settings.protectionEnabled) {
      // Protection OFF: stop reading messages entirely.
      // The native side's fallback has been removed so cancelling
      // the stream here is now safe — nothing will fire in its place.
      if (_listening) {
        await _service.stopListening();
        await _notificationSubscription?.cancel();
        _notificationSubscription = null;
        _listening = false;
      }
    } else {
      // Protection ON: start reading and processing messages.
      if (_permissionEnabled && !_listening) {
        await _service.startListening();
        _listening = true;
        await _attachStreamListener();
      }
    }

    notifyListeners();
  }

  void _attachSettingsListener() {
    if (_settingsListenerAttached) return;
    _lastProtectionEnabled = _settingsService.settings.protectionEnabled;
    _settingsService.addListener(_handleSettingsChange);
    _settingsListenerAttached = true;
  }

  void _handleSettingsChange() {
    final enabled = _settingsService.settings.protectionEnabled;
    if (enabled == _lastProtectionEnabled) return;
    _lastProtectionEnabled = enabled;
    unawaited(applyProtectionSetting());
  }

  /// Refresh permission status and restart listener if needed.
  ///
  /// Call this after the user grants permission in settings.
  Future<void> refreshPermission() async {
    debugPrint('[NotificationListenerProvider] Refreshing permission...');

    try {
      final current = await _service.isPermissionEnabled();
      if (current != _permissionEnabled) {
        debugPrint(
          '[NotificationListenerProvider] Permission changed: $_permissionEnabled → $current',
        );
        _permissionEnabled = current;
        notifyListeners();
      }

      if (_permissionEnabled &&
          !_listening &&
          _settingsService.settings.protectionEnabled) {
        debugPrint(
          '[NotificationListenerProvider] Starting listener after permission grant...',
        );
        await _service.startListening();
        _listening = true;
        notifyListeners();

        await _attachStreamListener();
        debugPrint(
          '[NotificationListenerProvider] Stream listener re-attached',
        );
      }
    } catch (e) {
      debugPrint('[NotificationListenerProvider] Error during refresh: $e');
    }
  }

  /// Process a notification event from the queue.
  Future<void> _processEvent(NotificationData event) async {
    try {
      await _settingsService.initialize();
      if (!_settingsService.settings.protectionEnabled) {
        debugPrint('[NotificationListenerProvider] Protection off, skipping.');
        return;
      }

      if (!_settingsService.isAppEnabled(event.appName)) {
        debugPrint('[NotificationListenerProvider] App disabled, skipping.');
        return;
      }

      // Log the captured notification
      _logCaptured(event);

      final message = event.message.trim();
      if (message.isEmpty) {
        debugPrint(
          '[NotificationListenerProvider] Skipping empty notification message.',
        );
        return;
      }

      // Run ML prediction. If TFLite is unavailable or throws, fall back
      // to a safe result so the notification is still stored in Realm.
      PredictionResult result;
      if (!_predictionReady) {
        debugPrint(
          '[NotificationListenerProvider] Prediction pipeline not ready, retrying initialization.',
        );
        await _initializePredictionPipeline();
      }

      if (_predictionReady) {
        try {
          result = await _predictionService.predict(message);
        } catch (e) {
          debugPrint(
            '[NotificationListenerProvider] Prediction failed: $e. Defaulting to safe.',
          );
          result = PredictionResult.safe();
        }
      } else {
        debugPrint(
          '[NotificationListenerProvider] ML model unavailable. Storing with safe default. Error: ${_predictionService.lastError}',
        );
        result = PredictionResult.safe();
      }

      _logScamDetection(event, result);

      final scamNotification = ScamNotification(
        appName: event.appName,
        sender: event.sender,
        message: event.message,
        receivedAt: event.receivedAt,
        riskScore: result.riskScore,
        isScam: result.isScam,
      );

      // Always persist detections (scam + safe) to Realm for offline-first UI.
      await _realmRepository.insertIfAbsent(scamNotification);

      // Only trigger local notification when risk is detected.
      if (result.isScam && _settingsService.settings.notificationsEnabled) {
        await NotificationService.showScamAlert(notification: scamNotification);
      }
    } catch (e) {
      debugPrint('[NotificationListenerProvider] Error handling event: $e');
    }
  }

  Future<void> _initializePredictionPipeline() async {
    try {
      await _predictionService.initialize();
      _predictionReady = _predictionService.isReady;
      if (_predictionReady) {
        debugPrint('[NotificationListenerProvider] Prediction pipeline ready.');
      } else {
        debugPrint('[NotificationListenerProvider] Prediction pipeline unavailable; detection disabled.');
      }
    } catch (e) {
      _predictionReady = false;
      debugPrint(
        '[NotificationListenerProvider] Prediction pipeline init failed: $e',
      );
    }
  }

  Future<void> _attachStreamListener() async {
    await _notificationSubscription?.cancel();
    _notificationSubscription = _service.stream.listen(
      (event) {
        if (!_settingsService.settings.protectionEnabled) {
          debugPrint(
            '[NotificationListenerProvider] Protection off, drop event.',
          );
          return;
        }
        _queueService.enqueue(event);
      },
      onError: (error, _) {
        debugPrint('[NotificationListenerProvider] Stream error: $error');
      },
    );
  }

  /// Log a captured notification to debug console.
  void _logCaptured(NotificationData event) {
    if (!kDebugMode) return;

    // Normalize whitespace
    String normalize(String value) {
      return value
          .replaceAll('\u00A0', ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }

    // Truncate long messages
    String truncate(String value, {int maxChars = 80}) {
      if (value.length <= maxChars) return value;
      return '${value.substring(0, maxChars)}…';
    }

    final app = normalize(event.appName);
    final sender = normalize(event.sender);
    final message = truncate(normalize(event.message));

    final timestamp = event.receivedAt.toString().split('.').first;
    debugPrint(
      '[NotificationListenerProvider] 📱 $app | $sender | $message ($timestamp)',
    );
  }

  void _logScamDetection(NotificationData event, PredictionResult result) {
    if (!kDebugMode) return;

    debugPrint(
      '[Scam Detection]\n'
      'App: ${event.appName}\n'
      'Sender: ${event.sender}\n'
      'Message: ${event.message}\n'
      'Risk Score: ${result.riskScore}\n'
      'Is Scam: ${result.isScam}',
    );
  }

  /// Open Android notification access settings page.
  Future<void> openNotificationAccessSettings() async {
    debugPrint(
      '[NotificationListenerProvider] Opening notification access settings...',
    );
    await _service.openNotificationAccessSettings();
  }

  @override
  void dispose() {
    debugPrint('[NotificationListenerProvider] Disposing...');
    unawaited(_notificationSubscription?.cancel() ?? Future<void>.value());
    unawaited(_queueService.dispose());
    if (_settingsListenerAttached) {
      _settingsService.removeListener(_handleSettingsChange);
    }
    _predictionService.dispose();
    _service.dispose();
    super.dispose();
  }
}
