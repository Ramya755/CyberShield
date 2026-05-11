import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'models/prediction_result.dart';

/// Runs scam detection inference via the native Android TFLite runtime.
///
/// The LSTM model requires SELECT_TF_OPS (flex ops) which the Flutter
/// tflite_flutter plugin's bundled runtime does not support. The native
/// Kotlin [NativeScamDetector] uses the gradle TFLite runtime which does
/// support flex ops, so we route inference through a MethodChannel.
class PredictionService {
  static const MethodChannel _channel = MethodChannel(
    'scam_detector/notification_listener_settings',
  );

  bool _initialized = false;
  bool _ready = false;
  String? _lastError;

  PredictionService({
    // Keep optional params for backward compatibility but they're unused now.
    dynamic tfliteService,
    dynamic tokenizerService,
  });

  bool get isReady => _ready;
  String? get lastError => _lastError;

  Future<void> initialize() async {
    if (_initialized && _ready) return;

    try {
      _lastError = null;
      // The native side initializes lazily on first predict() call.
      // Just mark as ready — the MethodChannel is always available.
      _ready = true;
      _initialized = true;
      debugPrint('[PredictionService] Native prediction pipeline ready.');
    } catch (e) {
      _ready = false;
      _initialized = false;
      _lastError = e.toString();
      debugPrint('[PredictionService] Initialization failed: $e');
    }
  }

  Future<PredictionResult> predict(String message) async {
    final content = message.trim();
    if (content.isEmpty) {
      throw ArgumentError('Message cannot be empty.');
    }

    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'predict',
        {'message': content},
      );

      if (result != null) {
        final riskScore = (result['riskScore'] as num?)?.toInt() ?? 0;
        final isScam = result['isScam'] as bool? ?? false;
        return PredictionResult(riskScore: riskScore, isScam: isScam);
      }

      debugPrint('[PredictionService] Native returned null, defaulting safe.');
      return PredictionResult.safe();
    } on PlatformException catch (e) {
      _lastError = e.message;
      debugPrint('[PredictionService] Native prediction error: ${e.message}');
      return PredictionResult.safe();
    } catch (e) {
      _lastError = e.toString();
      debugPrint('[PredictionService] Prediction failed: $e');
      return PredictionResult.safe();
    }
  }

  void dispose() {
    _initialized = false;
    _ready = false;
  }
}

