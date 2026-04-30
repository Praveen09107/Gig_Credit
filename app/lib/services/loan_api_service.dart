import 'dart:convert';
import 'package:http/http.dart' as http;

class LoanApiService {
  // Try 172.17.101.115 or 192.168.137.1 based on Wi-Fi
  final String baseUrl = 'http://172.17.101.115:8000';

  Future<Map<String, dynamic>> getProducts(int score) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/loan/products'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'score': score}),
      ).timeout(const Duration(seconds: 4));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to load products');
    } catch (e) {
      print('Falling back to mock products: $e');
      // Mock Fallback
      await Future.delayed(const Duration(seconds: 1));
      return {
        "eligible_products": [
          {
            "id": "emergency_advance",
            "name": "Emergency Cash Advance",
            "description": "Instant funds for medical, equipment or urgent needs",
            "max_amount": 100000,
            "min_amount": 10000,
            "tenures": [1, 2, 3],
            "apr": {"520-599": "22%", "600-639": "19%", "640-719": "16%", "720+": "14%"}
          },
          {
            "id": "working_capital",
            "name": "Working Capital Loan",
            "description": "Fund inventory, materials or business operations",
            "max_amount": 500000,
            "min_amount": 25000,
            "tenures": [3, 6, 9, 12, 18],
            "apr": {"600-639": "18%", "640-719": "16%", "720-799": "14%", "800+": "12%"}
          }
        ]
      };
    }
  }

  Future<Map<String, dynamic>> generateKfs(double amount, int tenure, String productId, int score) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/loan/kfs'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': amount,
          'tenure': tenure,
          'product_id': productId,
          'score': score,
        }),
      ).timeout(const Duration(seconds: 4));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to generate KFS');
    } catch (e) {
      print('Falling back to mock KFS: $e');
      await Future.delayed(const Duration(seconds: 1));
      return {
        "amount": amount,
        "tenure": tenure,
        "apr": 16.0,
        "emi": (amount / tenure) * 1.05,
        "total_payable": amount * 1.08,
        "processing_fee": amount * 0.02
      };
    }
  }

  Future<Map<String, dynamic>> applyLoan(Map<String, dynamic> application, Map<String, dynamic> scoreReport) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/loan/apply'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'application': application,
          'score_report': scoreReport,
        }),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to submit application');
    } catch (e) {
      print('Falling back to mock decision: $e');
      await Future.delayed(const Duration(seconds: 2));
      return {
        "decision": "rejected",
        "rejection_bucket": "AFFORDABILITY",
        "reason": "Requested loan amount exceeds safe EMI thresholds.",
        "counter_offer": {
           "amount": application["loan_amount"] * 0.5,
           "message": "We can approve you for a reduced amount."
        }
      };
    }
  }
}
