import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/app_config.dart';

final loanApiServiceProvider = Provider((ref) => LoanApiService());

class LoanApiService {
  final String baseUrl = AppConfig.baseUrl;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'X-API-Key': AppConfig.apiKey,
  };

  Future<Map<String, dynamic>> getProducts(int score) async {
    final response = await http.post(
      Uri.parse('$baseUrl/loan/products'),
      headers: _headers,
      body: jsonEncode({'score': score}),
    ).timeout(const Duration(seconds: 10));
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final errorMsg = jsonDecode(response.body)['detail'] ?? 'Failed to load loan products';
    throw Exception(errorMsg);
  }

  Future<Map<String, dynamic>> generateKfs(double amount, int tenure, String productId, int score) async {
    final response = await http.post(
      Uri.parse('$baseUrl/loan/kfs'),
      headers: _headers,
      body: jsonEncode({
        'amount': amount,
        'tenure': tenure,
        'product_id': productId,
        'score': score,
      }),
    ).timeout(const Duration(seconds: 10));
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final errorMsg = jsonDecode(response.body)['detail'] ?? 'Failed to generate KFS';
    throw Exception(errorMsg);
  }

  Future<Map<String, dynamic>> applyLoan(Map<String, dynamic> application, Map<String, dynamic> scoreReport) async {
    final response = await http.post(
      Uri.parse('$baseUrl/loan/apply'),
      headers: _headers,
      body: jsonEncode({
        'application': application,
        'score_report': scoreReport,
        'meta_probability': scoreReport['metaProbability'] ?? scoreReport['probability'] ?? 0.85,
      }),
    ).timeout(const Duration(seconds: 15));
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final errorMsg = jsonDecode(response.body)['detail'] ?? 'Failed to submit loan application';
    throw Exception(errorMsg);
  }
}
