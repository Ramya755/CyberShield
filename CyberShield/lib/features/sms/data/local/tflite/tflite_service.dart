import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class TfliteService {
  static const String _modelAssetPath = 'assets/models/sms_model.tflite';

  Interpreter? _interpreter;
  int _inputSequenceLength = 100;
  bool _initialized = false;

  bool get isInitialized => _initialized;
  int get inputSequenceLength => _inputSequenceLength;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // tflite_flutter 0.11.x loads SELECT_TF_OPS (flex ops) automatically
      // via the native gradle dependency tensorflow-lite-select-tf-ops.
      // No Dart-side delegate is needed — plain InterpreterOptions is correct.
      final options = InterpreterOptions()..threads = 2;

      _interpreter = await Interpreter.fromAsset(
        _modelAssetPath,
        options: options,
      );
      _inputSequenceLength = _resolveInputSequenceLength();
      _initialized = true;

      debugPrint(
        '[TfliteService] Model loaded. Input length=$_inputSequenceLength',
      );
    } catch (e) {
      _interpreter = null;
      _initialized = false;
      throw StateError('Failed to load model asset $_modelAssetPath: $e');
    }
  }

  Future<double> runInference(List<int> tokens) async {
    if (!_initialized || _interpreter == null) {
      throw StateError('TfliteService is not initialized.');
    }

    if (tokens.isEmpty) {
      throw ArgumentError('Input token list cannot be empty.');
    }

    final inputTensor = _interpreter!.getInputTensor(0);
    final outputTensor = _interpreter!.getOutputTensor(0);
    _validateTensorShapes(inputTensor.shape, outputTensor.shape, tokens.length);

    final dynamic input;
    final isFloatInput = inputTensor.type.toString().toLowerCase().contains(
      'float32',
    );
    if (isFloatInput) {
      input = <List<double>>[
        tokens.map((e) => e.toDouble()).toList(growable: false),
      ];
    } else {
      input = <List<int>>[tokens];
    }

    final dynamic output;
    final outputShape = outputTensor.shape;
    if (outputShape.length == 2) {
      output = <List<double>>[
        List<double>.filled(outputShape[1], 0.0, growable: false),
      ];
    } else {
      output = List<double>.filled(
        outputTensor.shape.reduce((a, b) => a * b),
        0.0,
        growable: false,
      );
    }

    _interpreter!.run(input, output);

    final raw = _extractScore(output);
    final normalized = raw >= 0.0 && raw <= 1.0 ? raw : _sigmoid(raw);

    return normalized.clamp(0.0, 1.0);
  }

  int _resolveInputSequenceLength() {
    final shape = _interpreter!.getInputTensor(0).shape;
    if (shape.length >= 2 && shape[1] > 0) {
      return shape[1];
    }
    throw FormatException('Invalid input tensor shape: $shape');
  }

  void _validateTensorShapes(
    List<int> inputShape,
    List<int> outputShape,
    int tokenLength,
  ) {
    if (inputShape.length < 2 || inputShape[1] <= 0) {
      throw FormatException('Invalid tensor shape (input): $inputShape');
    }
    if (outputShape.isEmpty) {
      throw FormatException('Invalid tensor shape (output): $outputShape');
    }
    if (tokenLength != inputShape[1]) {
      throw FormatException(
        'Input token length ($tokenLength) does not match model sequence length (${inputShape[1]}).',
      );
    }
  }

  double _extractScore(dynamic output) {
    if (output is List && output.isNotEmpty) {
      final first = output.first;

      if (first is List && first.isNotEmpty) {
        final row = first;
        final value = row.length == 1 ? row.first : row.last;
        if (value is num) return value.toDouble();
      }

      if (first is num) return first.toDouble();
    }
    throw const FormatException('Model output format is not supported.');
  }

  double _sigmoid(double x) {
    return 1.0 / (1.0 + math.exp(-x));
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _initialized = false;
  }
}
