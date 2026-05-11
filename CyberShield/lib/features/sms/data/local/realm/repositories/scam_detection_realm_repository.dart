import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:realm/realm.dart';
import 'package:scam_detector/features/sms/domain/repositories/scam_detection_repository.dart';
import 'package:scam_detector/features/sms/domain/models/scam_notification.dart';

import '../realm_models/scam_detection_realm.dart';
import '../realm_service.dart';

class ScamDetectionRealmRepository implements ScamDetectionRepository {
  ScamDetectionRealmRepository({RealmService? realmService})
    : _realmService = realmService ?? RealmService.instance;

  final RealmService _realmService;

  Realm get _realm => _realmService.realm;

  @override
  Future<void> initialize() async {
    await _realmService.initialize();
  }

  @override
  Future<bool> insertIfAbsent(ScamNotification notification) async {
    final id = notification.eventId;
    final existing = _realm.find<ScamDetectionRealm>(id);
    if (existing != null) {
      if (kDebugMode) {
        debugPrint('[RealmRepository] Duplicate skipped: $id');
      }
      return false;
    }

    try {
      _realm.write(() {
        _realm.add(
          ScamDetectionRealm(
            id,
            notification.appName,
            notification.sender,
            notification.message,
            notification.receivedAt,
            notification.riskScore,
            notification.isScam,
            false,
          ),
        );
      });

      if (kDebugMode) {
        debugPrint('[RealmRepository] Insert success: $id');
      }
      return true;
    } catch (e) {
      debugPrint('[RealmRepository] Insert failure: $id, error: $e');
      return false;
    }
  }

  @override
  Future<bool> insertRestoredIfAbsent(ScamNotification notification) async {
    final id = notification.eventId;
    final existing = _realm.find<ScamDetectionRealm>(id);
    if (existing != null) {
      if (kDebugMode) {
        debugPrint('[RealmRepository] Restore duplicate skipped: $id');
      }
      return false;
    }

    try {
      _realm.write(() {
        _realm.add(
          ScamDetectionRealm(
            id,
            notification.appName,
            notification.sender,
            notification.message,
            notification.receivedAt,
            notification.riskScore,
            notification.isScam,
            true,
          ),
        );
      });

      if (kDebugMode) {
        debugPrint('[RealmRepository] Restore insert success: $id');
      }
      return true;
    } catch (e) {
      debugPrint('[RealmRepository] Restore insert failure: $id, error: $e');
      return false;
    }
  }

  @override
  bool isEmpty() {
    final count = _realm.all<ScamDetectionRealm>().length;
    return count == 0;
  }

  @override
  List<ScamNotification> getPendingSyncItems() {
    final results = _realm.all<ScamDetectionRealm>().query(
      'isSynced == false SORT(receivedAt ASC)',
    );

    final list = results.map(_toDomain).toList(growable: false);
    if (kDebugMode) {
      debugPrint('[RealmRepository] Pending sync items: ${list.length}');
    }
    return list;
  }

  @override
  Future<void> markSynced(String id) async {
    final target = _realm.find<ScamDetectionRealm>(id);
    if (target == null) {
      debugPrint('[RealmRepository] markSynced skipped, missing id: $id');
      return;
    }

    try {
      _realm.write(() {
        target.isSynced = true;
      });
      if (kDebugMode) {
        debugPrint('[RealmRepository] Mark synced success: $id');
      }
    } catch (e) {
      debugPrint('[RealmRepository] Mark synced failure: $id, error: $e');
      rethrow;
    }
  }

  @override
  List<ScamNotification> getAllSorted() {
    final results = _realm.all<ScamDetectionRealm>().query(
      r'TRUEPREDICATE SORT(receivedAt DESC)',
    );

    final list = results.map(_toDomain).toList(growable: false);
    if (kDebugMode) {
      debugPrint('[RealmRepository] Query results: ${list.length}');
    }
    return list;
  }

  @override
  Stream<List<ScamNotification>> watchAllSorted() {
    final results = _realm.all<ScamDetectionRealm>().query(
      r'TRUEPREDICATE SORT(receivedAt DESC)',
    );

    return results.changes.map((changes) {
      final list = changes.results.map(_toDomain).toList(growable: false);
      if (kDebugMode) {
        debugPrint('[RealmRepository] Query results: ${list.length}');
      }
      return list;
    });
  }

  @override
  Future<void> deleteById(String id) async {
    final target = _realm.find<ScamDetectionRealm>(id);
    if (target == null) return;

    _realm.write(() {
      _realm.delete(target);
    });
  }

  @override
  Future<void> clearAll() async {
    try {
      _realm.write(() {
        _realm.deleteAll<ScamDetectionRealm>();
      });
      debugPrint('[RealmRepository] Cleared all detections.');
    } catch (e) {
      debugPrint('[RealmRepository] Clear all failed: $e');
    }
  }

  ScamNotification _toDomain(ScamDetectionRealm model) {
    return ScamNotification(
      appName: model.appName,
      sender: model.sender,
      message: model.message,
      receivedAt: model.receivedAt,
      riskScore: model.riskScore,
      isScam: model.isScam,
    );
  }
}
