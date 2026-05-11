import 'package:flutter/foundation.dart';
import 'package:mongo_dart/mongo_dart.dart';

import 'package:scam_detector/features/sms/domain/models/scam_notification.dart';

import '../mongodb_service.dart';

class NotificationDetectionMongoRepository {
  NotificationDetectionMongoRepository({MongoDbService? mongoService})
    : _mongoService = mongoService ?? MongoDbService.instance;

  final MongoDbService _mongoService;

  DbCollection get _collection => _mongoService.collection;

  Future<void> initialize() async {
    await _mongoService.initialize();
  }

  Future<bool> uploadIfAbsent(ScamNotification notification) async {
    if (!_mongoService.isInitialized) {
      debugPrint('[MongoRepository] MongoDB not configured; upload skipped.');
      return false;
    }

    final existing = await _collection.findOne(
      where
          .eq('appName', notification.appName)
          .eq('sender', notification.sender)
          .eq('message', notification.message)
          .eq('receivedAt', notification.receivedAt)
          .eq('riskScore', notification.riskScore)
          .eq('isScam', notification.isScam),
    );

    if (existing != null) {
      if (kDebugMode) {
        debugPrint('[MongoRepository] Duplicate skipped for cloud upload.');
      }
      return true;
    }

    try {
      await _collection.insertOne({
        '_id': ObjectId(),
        'appName': notification.appName,
        'sender': notification.sender,
        'message': notification.message,
        'receivedAt': notification.receivedAt,
        'riskScore': notification.riskScore,
        'isScam': notification.isScam,
      });

      if (kDebugMode) {
        debugPrint('[MongoRepository] Upload success: ${notification.eventId}');
      }
      return true;
    } catch (e) {
      debugPrint(
        '[MongoRepository] Upload failed: ${notification.eventId}, error: $e',
      );
      return false;
    }
  }
}
