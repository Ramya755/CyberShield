import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'package:scam_detector/features/sms/domain/repositories/scam_detection_repository.dart';
import 'package:scam_detector/features/sms/data/local/realm/repositories/scam_detection_realm_repository.dart';
import 'package:scam_detector/core/reliability/processing_lock_service.dart';
import 'package:scam_detector/core/settings/settings_service.dart';
import 'mongodb_service.dart';
import 'repositories/notification_detection_mongo_repository.dart';

class MongoSyncService {
  MongoSyncService._({
    ScamDetectionRepository? realmRepository,
    NotificationDetectionMongoRepository? mongoRepository,
    Connectivity? connectivity,
  }) : _realmRepository = realmRepository ?? ScamDetectionRealmRepository(),
       _mongoRepository =
           mongoRepository ?? NotificationDetectionMongoRepository(),
       _connectivity = connectivity ?? Connectivity();

  static final MongoSyncService instance = MongoSyncService._();

  final ScamDetectionRepository _realmRepository;
  final NotificationDetectionMongoRepository _mongoRepository;
  final Connectivity _connectivity;
  final ProcessingLockService _processingLock = ProcessingLockService.instance;
  SettingsService _settingsService = SettingsService();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _retryTimer;
  bool _initialized = false;
  bool _syncing = false;

  void configure({SettingsService? settingsService}) {
    if (settingsService == null) return;
    if (identical(_settingsService, settingsService)) return;
    _settingsService = settingsService;
  }

  Future<void> initialize() async {
    if (_initialized) return;

    await _realmRepository.initialize();
    await _mongoRepository.initialize();
    _initialized = true;
    debugPrint('[MongoSyncService] Initialized.');
  }

  Future<void> start() async {
    await initialize();

    await _settingsService.initialize();
    if (!_settingsService.settings.mongoAutoSyncEnabled) {
      debugPrint('[MongoSyncService] Auto-sync disabled, start skipped.');
      return;
    }

    if (!MongoDbService.instance.isConfigured) {
      debugPrint('[MongoSyncService] MongoDB not configured; sync disabled.');
      return;
    }

    // Initial sync is handled separately by the app bootstrap.
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      results,
    ) {
      if (_hasInternet(results)) {
        debugPrint(
          '[MongoSyncService] Connectivity restored, triggering sync.',
        );
        unawaited(syncPending());
      } else {
        debugPrint('[MongoSyncService] Internet unavailable.');
      }
    });

    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      unawaited(syncPending());
    });

    debugPrint('[MongoSyncService] Background sync monitor started.');
  }

  Future<void> syncPending() async {
    if (!_initialized) {
      await initialize();
    }

    if (!MongoDbService.instance.isConfigured) {
      debugPrint('[MongoSyncService] MongoDB not configured; sync skipped.');
      return;
    }

    await _settingsService.initialize();
    if (!_settingsService.settings.mongoAutoSyncEnabled) {
      debugPrint('[MongoSyncService] Auto-sync disabled, skipping.');
      return;
    }

    if (_syncing) {
      debugPrint('[MongoSyncService] Sync already in progress, skipping.');
      return;
    }

    final connectivity = await _connectivity.checkConnectivity();
    if (!_hasInternet(connectivity)) {
      debugPrint('[MongoSyncService] Internet unavailable.');
      return;
    }

    _syncing = true;
    try {
      await _processingLock.runExclusive('mongo_sync', () async {
        debugPrint('[MongoSyncService] Sync started.');
        final pending = _realmRepository.getPendingSyncItems();
        if (pending.isEmpty) {
          debugPrint('[MongoSyncService] No pending Realm items to sync.');
          return;
        }

        for (final item in pending) {
          final uploaded = await _mongoRepository.uploadIfAbsent(item);
          if (uploaded) {
            await _realmRepository.markSynced(item.eventId);
          } else {
            debugPrint(
              '[MongoSyncService] Upload skipped/failed for ${item.eventId}.',
            );
          }
        }

        debugPrint('[MongoSyncService] Sync completed.');
      });
    } catch (e) {
      debugPrint('[MongoSyncService] Sync failed: $e');
    } finally {
      _syncing = false;
    }
  }

  bool _hasInternet(List<ConnectivityResult> results) {
    return results.isNotEmpty && !results.contains(ConnectivityResult.none);
  }

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    _retryTimer?.cancel();
    _connectivitySubscription = null;
    _retryTimer = null;
  }
}
