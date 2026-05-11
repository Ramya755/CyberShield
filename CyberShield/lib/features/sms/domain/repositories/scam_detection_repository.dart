import 'package:scam_detector/features/sms/domain/models/scam_notification.dart';

/// Domain contract for scam detection persistence.
///
/// Providers and services should depend on this abstraction rather than
/// concrete storage implementations.
abstract class ScamDetectionRepository {
  Future<void> initialize();

  Future<bool> insertIfAbsent(ScamNotification notification);

  Future<bool> insertRestoredIfAbsent(ScamNotification notification);

  bool isEmpty();

  List<ScamNotification> getPendingSyncItems();

  Future<void> markSynced(String id);

  List<ScamNotification> getAllSorted();

  Stream<List<ScamNotification>> watchAllSorted();

  Future<void> deleteById(String id);

  Future<void> clearAll();
}
