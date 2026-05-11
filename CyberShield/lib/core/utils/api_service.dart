import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/threat.dart';
import '../../config/app_config.dart';

class ApiService {
  // Fetches only the most recent threats for the Home Screen
  static Future<List<Threat>> getRecentThreats() async {
    try {
      final response = await http.get(
        Uri.parse(AppConfig.recentScansEndpoint),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw Exception('Connection timeout'),
      );

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        final List<dynamic> jsonData = _extractList(decodedData);

        return jsonData
            .map((item) => Threat.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Could not reach server. Check backend.');
    }
  }

  // Helper to handle different JSON formats from Node.js
  static List<dynamic> _extractList(dynamic decodedData) {
    if (decodedData is List) return decodedData;
    if (decodedData is Map<String, dynamic>) {
      return decodedData['data'] ?? decodedData['scans'] ?? decodedData['threats'] ?? [];
    }
    return [];
  }
}
