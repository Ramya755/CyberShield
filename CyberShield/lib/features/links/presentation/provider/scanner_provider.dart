import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform, SocketException;
import 'dart:async' show TimeoutException;
import '../../data/services/history_services.dart';

class ScannerProvider extends ChangeNotifier {
  // Google Safe Browsing API Configuration
  static const String _googleSafeBrowsingApiKey = 'AIzaSyDAfiFCkhe7tHzvDuQ0y3nEQwE0tEUBZn0';
  static const String _googleSafeBrowsingUrl = 'https://safebrowsing.googleapis.com/v4/threatMatches:find';
  static const Duration _apiTimeout = Duration(seconds: 10);
  static const int _dangerousThreshold = 70;
  static const int _suspiciousThreshold = 40;

  List<dynamic> historyList = [];

  int riskScore = 0;
  List<String> reasons = [];
  String result = "";
  bool isLoading = false;
  String? lastError;

  /// LOAD HISTORY
  Future<void> loadHistory() async {
    try {
      historyList = await HistoryService.getHistory();
      lastError = null;
      notifyListeners();
    } catch (e) {
      lastError = 'Failed to load history: $e';
      debugPrint(lastError);
      notifyListeners();
    }
  }

  /// VALIDATE URL FORMAT
  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// SCAN LINK
  Future<void> scanLink(String url) async {
    if (url.isEmpty) {
      result = "No valid link found";
      reasons = ["URL is empty"];
      riskScore = 0;
      lastError = null;
      notifyListeners();
      return;
    }

    if (!_isValidUrl(url)) {
      result = "Invalid URL format";
      reasons = ["URL must start with http:// or https://"];
      riskScore = 20;
      lastError = null;
      notifyListeners();
      return;
    }

    isLoading = true;
    result = "";
    reasons = [];
    riskScore = 0;
    lastError = null;
    notifyListeners();

    try {
      final data = await checkUrlWithGoogleSafeBrowsing(url);

      riskScore = (data["score"] as int).clamp(0, 100);
      reasons = List<String>.from(data["reasons"] as List);

      if (riskScore >= _dangerousThreshold) {
        result = "🚨 Dangerous Link!";
      } else if (riskScore >= _suspiciousThreshold) {
        result = "⚠️ Suspicious Link";
      } else {
        result = "✅ Safe Link";
      }
    } on SocketException catch (e) {
      result = "Network Error";
      reasons = ["No internet connection: ${e.message}"];
      riskScore = 0;
      lastError = "Network error: ${e.message}";
    } on TimeoutException {
      result = "Analysis Timeout";
      reasons = ["Request took too long"];
      riskScore = 0;
      lastError = "Timeout error";
    } catch (e) {
      result = "Unable to analyze link";
      reasons = ["Error: $e"];
      riskScore = 0;
      lastError = e.toString();
      debugPrint("Error analyzing URL: $e");
    }

    isLoading = false;
    notifyListeners();

    // Save scan result to history
    try {
      await HistoryService.saveScan(
        url: url,
        status: result,
        riskScore: riskScore,
      );
      await loadHistory();
    } catch (e) {
      debugPrint("Failed to save scan history: $e");
    }
  }

  /// GOOGLE SAFE BROWSING API CHECK
  Future<Map<String, dynamic>> checkUrlWithGoogleSafeBrowsing(String url) async {
    int score = 0;
    List<String> reasons = [];

    try {
      // Build request with platform-specific threat types
      final List<String> platformTypes = _getPlatformTypes();

      final requestBody = {
        'client': {
          'clientId': 'cybershield',
          'clientVersion': '1.0.0',
        },
        'threatInfo': {
          'threatTypes': [
            'MALWARE',
            'SOCIAL_ENGINEERING',
            'UNWANTED_SOFTWARE',
            'POTENTIALLY_HARMFUL_APPLICATION',
          ],
          'platformTypes': platformTypes,
          'threatEntryTypes': ['URL'],
          'threatEntries': [
            {'url': url}
          ],
        },
      };

      final uri = Uri.parse(_googleSafeBrowsingUrl)
          .replace(queryParameters: {'key': _googleSafeBrowsingApiKey});

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(_apiTimeout);

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body) as Map<String, dynamic>;

        // Check if matches found, URL is flagged
        if (responseBody.containsKey('matches') && responseBody['matches'] != null) {
          final matches = responseBody['matches'] as List<dynamic>? ?? [];

         if (matches.isEmpty) {
  score = 0;
  reasons.add('✓ No threats detected by Google Safe Browsing');
} else {
  for (var match in matches) {
    if (match is! Map<String, dynamic>) continue;

    final threatType =
        match['threatType'] as String? ?? 'UNKNOWN';

    final platformType =
        match['platformType'] as String? ?? 'UNKNOWN';

    switch (threatType) {
      case 'MALWARE':
        score = 100;
        reasons.add('⚠️ MALWARE detected');
        break;

      case 'SOCIAL_ENGINEERING':
        score = 90;
        reasons.add(
          '⚠️ SOCIAL_ENGINEERING threat detected',
        );
        break;

      case 'UNWANTED_SOFTWARE':
        score = 75;
        reasons.add(
          '⚠️ UNWANTED_SOFTWARE detected',
        );
        break;

      case 'POTENTIALLY_HARMFUL_APPLICATION':
        score = 85;
        reasons.add(
          '⚠️ POTENTIALLY_HARMFUL_APPLICATION detected',
        );
        break;

      default:
        score = 50;
        reasons.add(
          '⚠️ Threat detected: $threatType',
        );
    }

    reasons.add(
      '  → Detected on: $platformType',
    );
  }

  score = score.clamp(0, 100);
} 
        } else {
          // URL is safe according to Google Safe Browsing
          score = 0;
          reasons.add('✓ No threats detected by Google Safe Browsing');
        }
      } else if (response.statusCode == 400) {
        reasons.add('Invalid URL format provided to API');
        score = 20;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        reasons.add('API authentication failed - invalid or expired key');
        score = 0;
        debugPrint('API Error: ${response.statusCode} - Check your API key');
      } else {
        reasons.add('API Error: ${response.statusCode}');
        score = 0;
        debugPrint('Unexpected API response: ${response.statusCode}\n${response.body}');
      }
    } on TimeoutException catch (e) {
      reasons.add('Request timed out after ${_apiTimeout.inSeconds} seconds');
      score = 0;
      debugPrint('API Timeout: $e');
    } on SocketException catch (e) {
      reasons.add('Network error: Unable to reach API');
      score = 0;
      debugPrint('Network Error: $e');
    } catch (e) {
      reasons.add('Failed to analyze URL: $e');
      score = 0;
      debugPrint('Unexpected error: $e');
      rethrow;
    }

    return {
      'score': score,
      'reasons': reasons,
    };
  }

  List<String> _getPlatformTypes() {
    if (Platform.isAndroid) {
      return ['ANDROID', 'ANY_PLATFORM'];
    } else if (Platform.isIOS) {
      return ['IOS', 'ANY_PLATFORM'];
    } else if (Platform.isWindows) {
      return ['WINDOWS', 'ANY_PLATFORM'];
    } else if (Platform.isLinux) {
      return ['LINUX', 'ANY_PLATFORM'];
    } else if (Platform.isMacOS) {
      return ['OSX', 'ANY_PLATFORM'];
    } else {
      return ['ANY_PLATFORM'];
    }
  }

  /// CLEAR HISTORY
  Future<void> clearHistory() async {
    try {
      historyList = [];
      reasons = [];
      riskScore = 0;
      result = "";
      lastError = null;
      notifyListeners();
    } catch (e) {
      lastError = 'Failed to clear history: $e';
      debugPrint(lastError);
      notifyListeners();
    }
  }

  /// RESET STATE
  void resetState() {
    riskScore = 0;
    reasons = [];
    result = "";
    isLoading = false;
    lastError = null;
    notifyListeners();
  }
}