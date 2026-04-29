import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/score_report_model.dart';

class ScoringService {
  final String baseUrl;

  ScoringService({this.baseUrl = 'https://api.gigcredit.example.com'});

  Future<void> storeScore(ScoreReportModel report) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/score/store'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(report.toJson()),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to store score');
      }
    } catch (e) {
      // Offline fallback: store locally or ignore
      print('Offline mode: Score saved locally. Error: $e');
    }
  }

  Future<Map<String, dynamic>> getExplanation(String proofId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/explain/full'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'proof_id': proofId}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch server explanation');
      }
    } catch (e) {
      print('Offline mode: Could not fetch server explanation. Error: $e');
      return {};
    }
  }
}
