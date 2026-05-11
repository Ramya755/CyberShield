import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:scam_detector/features/sms/domain/repositories/scam_detection_repository.dart';
import 'package:scam_detector/core/settings/settings_service.dart';
import 'package:scam_detector/features/sms/domain/models/scam_notification.dart';
import 'package:scam_detector/features/sms/domain/models/scam_message.dart';

class ScamDetectionProvider extends ChangeNotifier {
  ScamDetectionProvider({
    required ScamDetectionRepository repository,
    SettingsService? settingsService,
  }) : _repository = repository,
       _settingsService = settingsService ?? SettingsService() {
    unawaited(_bindRealm());
    unawaited(_bindSettings());
  }

  final ScamDetectionRepository _repository;
  SettingsService _settingsService;
  StreamSubscription<List<ScamNotification>>? _subscription;

  bool _isProtectionEnabled = true;
  List<ScamMessage> _messages = const [];

  bool get isProtectionEnabled => _isProtectionEnabled;
  List<ScamMessage> get messages => List.unmodifiable(_messages);

  List<ScamMessage> get recentDetections {
    final sorted = [..._messages]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted.take(4).toList();
  }

  int get totalScanned => _messages.length;
  int get totalScams => _messages.where((m) => m.isScam).length;
  int get safeMessages => _messages.where((m) => !m.isScam).length;

  void updateSettingsService(SettingsService service) {
    if (identical(_settingsService, service)) return;

    _settingsService.removeListener(_handleSettingsChange);
    _settingsService = service;
    _settingsService.addListener(_handleSettingsChange);
    unawaited(_initializeSettings());
  }

  Future<void> _bindRealm() async {
    try {
      await _repository.initialize();
    } catch (e) {
      debugPrint('[ScamDetectionProvider] Realm init failed: $e');
      return;
    }

    // Initial snapshot for first paint.
    final initial = _repository.getAllSorted();
    _messages = initial.map(_toScamMessage).toList(growable: false);
    notifyListeners();

    await _subscription?.cancel();
    _subscription = _repository.watchAllSorted().listen((detections) {
      _messages = detections.map(_toScamMessage).toList(growable: false);
      notifyListeners();
    });
  }

  Future<void> _bindSettings() async {
    _settingsService.addListener(_handleSettingsChange);
    await _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    await _settingsService.initialize();
    _handleSettingsChange();
  }

  void _handleSettingsChange() {
    final enabled = _settingsService.settings.protectionEnabled;
    if (enabled == _isProtectionEnabled) return;
    _isProtectionEnabled = enabled;
    notifyListeners();
  }

  Future<void> toggleProtection() async {
    final next = !_settingsService.settings.protectionEnabled;
    await _settingsService.setProtectionEnabled(next);
  }

  List<ScamMessage> getMessagesByType(String appName) {
    return _messages
        .where(
          (message) => message.appName.toLowerCase() == appName.toLowerCase(),
        )
        .toList();
  }

  Future<void> addDetection(ScamMessage detection) async {
    await _repository.insertIfAbsent(
      ScamNotification(
        appName: detection.appName,
        sender: detection.sender,
        message: detection.message,
        receivedAt: detection.timestamp,
        riskScore: detection.riskScore,
        isScam: detection.isScam,
      ),
    );
  }

  Future<void> removeDetection(String id) async {
    await _repository.deleteById(id);
  }

  ScamMessage _toScamMessage(ScamNotification detection) {
    return ScamMessage(
      id: detection.eventId,
      appName: detection.appName,
      sender: detection.sender,
      message: detection.message,
      riskScore: detection.riskScore,
      isScam: detection.isScam,
      timestamp: detection.receivedAt,
    );
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel() ?? Future<void>.value());
    _settingsService.removeListener(_handleSettingsChange);
    super.dispose();
  }
}
