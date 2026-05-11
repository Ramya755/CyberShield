import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:mongo_dart/mongo_dart.dart';

import 'package:scam_detector/features/sms/domain/repositories/scam_detection_repository.dart';
import 'package:scam_detector/features/sms/data/local/realm/repositories/scam_detection_realm_repository.dart';
import 'package:scam_detector/features/sms/domain/models/scam_notification.dart';
import 'mongodb_service.dart';

class MongoRestoreService {
  MongoRestoreService._({
    ScamDetectionRepository? realmRepository,
    MongoDbService? mongoService,
    Connectivity? connectivity,
  }) : _realmRepository = realmRepository ?? ScamDetectionRealmRepository(),
       _mongoService = mongoService ?? MongoDbService.instance,
       _connectivity = connectivity ?? Connectivity();

  static final MongoRestoreService instance = MongoRestoreService._();

  final ScamDetectionRepository _realmRepository;
  final MongoDbService _mongoService;
  final Connectivity _connectivity;

  bool _initialized = false;
  bool _restoring = false;

  Future<void> initialize() async {
    if (_initialized) return;

    await _realmRepository.initialize();
    await _mongoService.initialize();
    _initialized = true;
    debugPrint('[MongoRestoreService] Initialized.');
  }

  /// Restore data from MongoDB into Realm when Realm is empty.
  ///
  /// Set [force] to true to trigger a restore regardless of Realm state.
  Future<void> restoreIfNeeded({bool force = false}) async {
    if (!_initialized) {
      await initialize();
    }

    if (!_mongoService.isInitialized) {
      debugPrint(
        '[MongoRestoreService] MongoDB not configured; restore skipped.',
      );
      return;
    }

    if (_restoring) {
      debugPrint(
        '[MongoRestoreService] Restore already in progress, skipping.',
      );
      return;
    }

    if (!force && !_realmRepository.isEmpty()) {
      debugPrint('[MongoRestoreService] Realm not empty, restore skipped.');
      return;
    }

    final connectivity = await _connectivity.checkConnectivity();
    if (!_hasInternetResults(connectivity)) {
      debugPrint('[MongoRestoreService] Internet unavailable.');
      return;
    }

    _restoring = true;
    try {
      debugPrint('[MongoRestoreService] Restore started.');
      final docs =
          await _mongoService.collection
              .find(where.sortBy('receivedAt', descending: false))
              .toList();
      if (kDebugMode) {
        debugPrint('[MongoRestoreService] Documents fetched: ${docs.length}');
      }

      for (final doc in docs) {
        final parsed = _parseDocument(doc);
        if (parsed == null) {
          if (kDebugMode) {
            debugPrint('[MongoRestoreService] Skipping malformed document.');
          }
          continue;
        }

        await _realmRepository.insertRestoredIfAbsent(parsed);
      }

      debugPrint('[MongoRestoreService] Restore completed.');
    } catch (e) {
      debugPrint('[MongoRestoreService] Restore failed: $e');
    } finally {
      _restoring = false;
    }
  }

  ScamNotification? _parseDocument(Map<String, dynamic> doc) {
    try {
      final appName = _asString(doc['appName']);
      final sender = _asString(doc['sender']);
      final message = _asString(doc['message']);
      final receivedAt = _asDateTime(doc['receivedAt']);
      final riskScore = _asInt(doc['riskScore']);
      final isScam = _asBool(doc['isScam']);

      if (appName.isEmpty || sender.isEmpty || message.isEmpty) {
        return null;
      }

      return ScamNotification(
        appName: appName,
        sender: sender,
        message: message,
        receivedAt: receivedAt,
        riskScore: riskScore,
        isScam: isScam,
      );
    } catch (_) {
      return null;
    }
  }

  bool _hasInternetResults(List<ConnectivityResult> results) {
    return results.isNotEmpty && !results.contains(ConnectivityResult.none);
  }

  String _asString(dynamic value) {
    return (value ?? '').toString().trim();
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  bool _asBool(dynamic value) {
    if (value is bool) return value;
    final normalized = (value?.toString() ?? '').toLowerCase();
    return normalized == 'true' || normalized == '1';
  }

  DateTime _asDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    return parsed ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
}
