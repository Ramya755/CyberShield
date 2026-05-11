import 'package:flutter/foundation.dart';
import 'package:mongo_dart/mongo_dart.dart';

import 'package:scam_detector/core/shared/app_config.dart';

class MongoDbService {
  MongoDbService._();

  static final MongoDbService instance = MongoDbService._();

  static const String databaseName = AppConfig.mongoDatabaseName;
  static const String collectionName = AppConfig.mongoCollectionName;

  Db? _db;
  DbCollection? _collection;

  bool get isInitialized => _db != null && _collection != null;
  bool get isConfigured => AppConfig.mongoConnectionString.isNotEmpty;

  DbCollection get collection {
    final value = _collection;
    if (value == null) {
      throw StateError('MongoDbService is not initialized.');
    }
    return value;
  }

  Future<void> initialize() async {
    if (isInitialized) return;

    if (!isConfigured) {
      debugPrint('[MongoDbService] Connection string missing; sync disabled.');
      return;
    }

    try {
      debugPrint('[MongoDbService] Connecting to MongoDB Atlas...');
      _db = await Db.create(AppConfig.mongoConnectionString);
      await _db!.open();
      _collection = _db!.collection(collectionName);
      debugPrint('[MongoDbService] Connected to $databaseName.$collectionName');
    } catch (e) {
      debugPrint('[MongoDbService] Connection failed: $e');
      rethrow;
    }
  }

  Future<void> close() async {
    try {
      await _db?.close();
      debugPrint('[MongoDbService] Connection closed.');
    } catch (e) {
      debugPrint('[MongoDbService] Close failed: $e');
    } finally {
      _db = null;
      _collection = null;
    }
  }
}
