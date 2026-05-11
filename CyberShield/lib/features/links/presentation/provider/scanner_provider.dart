import 'package:flutter/material.dart';
import '../../data/services/history_services.dart';

class ScannerProvider extends ChangeNotifier {
  List historyList = [];

  int riskScore = 0;
  List<String> reasons = [];
  String result = "";
  bool isLoading = false;

  /// LOAD HISTORY
  Future<void> loadHistory() async {
    historyList = await HistoryService.getHistory();
    notifyListeners();
  }

  /// SCAN LINK
  Future<void> scanLink(String url) async {
    if (url.isEmpty) {
      result = "No valid link found";
      notifyListeners();
      return;
    }

    isLoading = true;
    result = "";
    reasons = [];
    riskScore = 0;
    notifyListeners();

    final data = analyzeUrl(url);

    await Future.delayed(const Duration(seconds: 2));

    riskScore = data["score"];
    reasons = List<String>.from(data["reasons"]);

    if (riskScore >= 70) {
      result = " Dangerous Link!";
    } else if (riskScore >= 40) {
      result = "Suspicious Link";
    } else {
      result = "Safe Link";
    }

    isLoading = false;
    notifyListeners();

    await HistoryService.saveScan(
      url: url,
      status: result,
      riskScore: riskScore,
    );

    await loadHistory();
  }

  /// URL ANALYSIS
  Map<String, dynamic> analyzeUrl(String url) {
    int score = 0;
    List<String> reasons = [];

    List<String> suspiciousWords = [
      "free",
      "win",
      "gift",
      "claim",
      "verify",
      "urgent",
      "reward",
      "login",
      "bank",
      "password",
      "bonus",
      "crypto",
      "offer",
      "update",
    ];

    if (url.startsWith("http://")) {
      score += 20;
      reasons.add("Uses insecure HTTP");
    }

    for (String word in suspiciousWords) {
      if (url.toLowerCase().contains(word)) {
        score += 15;
        reasons.add("Contains suspicious word: $word");
      }
    }

    if ("-".allMatches(url).length > 2) {
      score += 10;
      reasons.add("Too many hyphens");
    }

    if (url.length > 70) {
      score += 10;
      reasons.add("Very long URL");
    }

    RegExp ipPattern = RegExp(r'\d+\.\d+\.\d+\.\d+');

    if (ipPattern.hasMatch(url)) {
      score += 25;
      reasons.add("Uses IP address instead of domain");
    }

    return {
      "score": score,
      "reasons": reasons,
    };
  }
}