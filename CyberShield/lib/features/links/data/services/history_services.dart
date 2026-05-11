import 'dart:convert';
import 'package:http/http.dart' as http;

class HistoryService {
  static const String baseUrl = "http://10.16.53.221:5000";

  /// SAVE SCAN
  static Future<void> saveScan({
    required String url,
    required String status,
    required int riskScore,
  }) async {
    try {
      await http.post(
        Uri.parse("$baseUrl/saveScan"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "url": url,
          "status": status,
          "riskScore": riskScore,
        }),
      );
    } catch (e) {
      print("Save Error: $e");
    }
  }

  /// GET HISTORY
  static Future<List<dynamic>> getHistory() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/history"),
        headers: {
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return [];
    } catch (e) {
      print("History Error: $e");
      return [];
    }
  }
}