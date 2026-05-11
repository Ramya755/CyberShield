import 'dart:convert';

import 'package:flutter/services.dart';

class TokenizerService {
  static const String _assetPath = 'assets/tokenizers/tokenizer.json';

  Map<String, int> _wordIndex = const {};
  int _oovTokenId = 1;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final raw = await rootBundle.loadString(_assetPath);
      dynamic decoded = jsonDecode(raw);

      // Some exported Keras tokenizers are serialized as a JSON string.
      if (decoded is String) {
        decoded = jsonDecode(decoded);
      }

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException(
          'Tokenizer root JSON is not a valid object.',
        );
      }

      final config = _asMap(decoded['config']);
      final wordIndexRaw = config['word_index'];
      final wordIndexMap = _decodeMap(wordIndexRaw);

      if (wordIndexMap.isEmpty) {
        throw const FormatException(
          'Tokenizer word_index is missing or empty.',
        );
      }

      _wordIndex = wordIndexMap.map(
        (key, value) => MapEntry(key.toLowerCase(), _toInt(value)),
      );

      _oovTokenId = _wordIndex['<oov>'] ?? _wordIndex['oov_token'] ?? 1;
      _initialized = true;
    } on FormatException {
      rethrow;
    } catch (e) {
      throw FormatException('Failed to parse tokenizer.json: $e');
    }
  }

  List<int> textToInputVector(String text, {required int maxLen}) {
    if (!_initialized) {
      throw StateError('TokenizerService is not initialized.');
    }
    if (maxLen <= 0) {
      throw ArgumentError.value(
        maxLen,
        'maxLen',
        'maxLen must be greater than 0.',
      );
    }

    final normalized = _normalize(text);
    if (normalized.isEmpty) {
      return List<int>.filled(maxLen, 0, growable: false);
    }

    final tokens = normalized
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) => _wordIndex[w] ?? _oovTokenId)
        .toList(growable: false);

    return _padPre(tokens, maxLen);
  }

  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll('\u00A0', ' ')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  List<int> _padPre(List<int> sequence, int maxLen) {
    if (sequence.length >= maxLen) {
      return sequence.sublist(sequence.length - maxLen);
    }

    final padding = List<int>.filled(
      maxLen - sequence.length,
      0,
      growable: false,
    );
    return <int>[...padding, ...sequence];
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, v) => MapEntry(key.toString(), v));
    }
    return const {};
  }

  static Map<String, dynamic> _decodeMap(dynamic value) {
    if (value is String) {
      try {
        final parsed = jsonDecode(value);
        return _asMap(parsed);
      } catch (_) {
        return const {};
      }
    }
    return _asMap(value);
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}
