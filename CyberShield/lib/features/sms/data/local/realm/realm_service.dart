import 'package:flutter/foundation.dart';
import 'package:realm/realm.dart';

import 'realm_config.dart';

class RealmService {
  RealmService._();

  static final RealmService instance = RealmService._();

  Realm? _realm;

  Realm get realm {
    final value = _realm;
    if (value == null) {
      throw StateError('RealmService is not initialized.');
    }
    return value;
  }

  Future<void> initialize() async {
    if (_realm != null) return;

    try {
      debugPrint('[RealmService] Initializing Realm...');
      final config = await RealmConfig.localConfig();
      _realm = Realm(config);
      debugPrint('[RealmService] Realm initialized successfully.');
    } catch (e) {
      debugPrint('[RealmService] Realm initialization failed: $e');
      rethrow;
    }
  }

  void close() {
    _realm?.close();
    _realm = null;
    debugPrint('[RealmService] Realm closed.');
  }
}
