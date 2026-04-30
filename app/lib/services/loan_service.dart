import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/loan_product_model.dart';
import '../models/kfs_model.dart';
import '../models/loan_decision_model.dart';

class LoanService {
  final String baseUrl;

  LoanService({this.baseUrl = 'https://gig-credit.onrender.com/api'});

  Future<List<LoanProductModel>> getProducts(String workType, int score) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/loan/products'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'work_type': workType, 'score': score}),
      );

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((e) => LoanProductModel.fromJson(e)).toList();
      } else {
        throw Exception('Failed to fetch loan products');
      }
    } catch (e) {
      print('Offline mode: Using mock loan products. Error: $e');
      return [
        LoanProductModel(
          id: 'p1',
          lenderName: 'Demo Bank',
          lenderLogoUrl: '',
          maxEligibleAmount: 50000,
          interestRate: 14.5,
          tenureMonths: 12,
          estimatedEmi: 4500,
          highlights: ['Instant Approval'],
          isEligible: true,
        ),
      ];
    }
  }

  Future<KfsModel> getKfs(String productId, double amount, int tenure) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/loan/kfs'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'product_id': productId,
          'amount': amount,
          'tenure_months': tenure,
        }),
      );

      if (response.statusCode == 200) {
        return KfsModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to fetch KFS');
      }
    } catch (e) {
      print('Offline mode: Using mock KFS. Error: $e');
      return KfsModel(
        loanAmount: amount,
        tenureDays: tenure * 30,
        interestRateAnnual: 14.5,
        processingFee: amount * 0.02,
        totalRepaymentAmount: amount * 1.1,
        apr: 15.5,
        coolingOffPeriod: '3 Days',
        penalChargePerDay: 50,
        grievanceOfficerContact: 'grievance@demobank.com',
      );
    }
  }

  Future<LoanDecisionModel> applyForLoan(String productId, double amount, int tenure) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/loan/apply'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'product_id': productId,
          'amount': amount,
          'tenure_months': tenure,
        }),
      );

      if (response.statusCode == 200) {
        return LoanDecisionModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to apply for loan');
      }
    } catch (e) {
      print('Offline mode: Using mock decision. Error: $e');
      return LoanDecisionModel(
        applicationId: 'app_123',
        status: LoanDecisionStatus.approved,
        approvedAmount: amount,
        interestRate: 14.5,
        tenureDays: tenure * 30,
      );
    }
  }
}
