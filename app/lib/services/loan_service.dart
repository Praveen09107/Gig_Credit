import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/loan_product_model.dart';
import '../models/kfs_model.dart';
import '../models/loan_decision_model.dart';
import '../core/config/app_config.dart';

class LoanService {
  final String baseUrl;

  LoanService({this.baseUrl = AppConfig.baseUrl});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'X-API-Key': AppConfig.apiKey,
  };

  Future<List<LoanProductModel>> getProducts(String workType, int score) async {
    final response = await http.post(
      Uri.parse('$baseUrl/loan/products'),
      headers: _headers,
      body: jsonEncode({'work_type': workType, 'score': score}),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((e) => LoanProductModel.fromJson(e)).toList();
    }
    throw Exception('Failed to fetch loan products (${response.statusCode})');
  }

  Future<KfsModel> getKfs(String productId, double amount, int tenure) async {
    final response = await http.post(
      Uri.parse('$baseUrl/loan/kfs'),
      headers: _headers,
      body: jsonEncode({
        'product_id': productId,
        'amount': amount,
        'tenure_months': tenure,
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return KfsModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to fetch KFS (${response.statusCode})');
  }

  Future<LoanDecisionModel> applyForLoan(String productId, double amount, int tenure) async {
    final response = await http.post(
      Uri.parse('$baseUrl/loan/apply'),
      headers: _headers,
      body: jsonEncode({
        'product_id': productId,
        'amount': amount,
        'tenure_months': tenure,
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return LoanDecisionModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to apply for loan (${response.statusCode})');
  }
}
