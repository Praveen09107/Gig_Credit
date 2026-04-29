import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class RealApiService implements ApiService {
  final String baseUrl;
  RealApiService({this.baseUrl = 'http://10.0.2.2:8000/api'});
  @override
  Future<Map<String, dynamic>> sendOtp(String mobile, {bool isSignup = false}) async {
    // MOCK AUTHENTICATION AS REQUESTED
    await Future.delayed(const Duration(milliseconds: 800));
    return {'status': 'success', 'message': 'OTP sent successfully'};
  }

  @override
  Future<Map<String, dynamic>> verifyOtp(String mobile, String otp) async {
    // MOCK AUTHENTICATION AS REQUESTED
    await Future.delayed(const Duration(milliseconds: 800));
    if (mobile == '7810039326' && otp == '0000') {
      return {'status': 'success', 'token': 'mock_jwt_token', 'user': {'name': 'Praveen Kumar', 'mobile': mobile}};
    }
    // Also accept 000000 as a fallback
    if (otp == '000000' || otp == '0000') {
      return {'status': 'success', 'token': 'mock_jwt_token', 'user': {'name': 'Praveen Kumar', 'mobile': mobile}};
    }
    throw Exception('Invalid OTP');
  }

  @override
  Future<Map<String, dynamic>> verifyAadhaar(String aadhaarNumber) async {
    final response = await http.post(
      Uri.parse('$baseUrl/gov/aadhaar/verify'),
      headers: {
        'Content-Type': 'application/json',
        'X-API-Key': 'gigcredit-demo-api-key-2026',
      },
      body: jsonEncode({'aadhaar': aadhaarNumber}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final errorMsg = jsonDecode(response.body)['detail'] ?? 'Failed to verify Aadhaar';
    throw Exception(errorMsg);
  }

  @override
  Future<Map<String, dynamic>> verifyPan(String panNumber) async {
    final response = await http.post(
      Uri.parse('$baseUrl/gov/pan/verify'),
      headers: {
        'Content-Type': 'application/json',
        'X-API-Key': 'gigcredit-demo-api-key-2026',
      },
      body: jsonEncode({'pan': panNumber}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final errorMsg = jsonDecode(response.body)['detail'] ?? 'Failed to verify PAN';
    throw Exception(errorMsg);
  }

  @override
  Future<Map<String, dynamic>> verifyAccount(String accountNo, String ifsc) async {
    final response = await http.post(
      Uri.parse('$baseUrl/bank/account/verify'),
      headers: {
        'Content-Type': 'application/json',
        'X-API-Key': 'gigcredit-demo-api-key-2026',
      },
      body: jsonEncode({'account_number': accountNo, 'ifsc': ifsc}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final errorMsg = jsonDecode(response.body)['detail'] ?? 'Failed to verify Account';
    throw Exception(errorMsg);
  }

  @override
  Future<Map<String, dynamic>> verifyIfsc(String ifsc) async {
    final response = await http.post(
      Uri.parse('$baseUrl/bank/ifsc/verify'),
      headers: {
        'Content-Type': 'application/json',
        'X-API-Key': 'gigcredit-demo-api-key-2026',
      },
      body: jsonEncode({'ifsc': ifsc}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final errorMsg = jsonDecode(response.body)['detail'] ?? 'Failed to verify IFSC';
    throw Exception(errorMsg);
  }

  @override
  Future<Map<String, dynamic>> uploadBankStatement(String base64Pdf) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> verifyUtility(String consumerNumber, String provider) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> verifyUan(String uanNumber) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> getGigHistory(String platformId) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> verifyEshram(String eshramNumber) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> verifyRationCard(String cardNumber) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> verifyAybha(String aybhaId) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> verifyGst(String gstNumber) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> uploadItr(String base64Itr) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> generateReportScore(Map<String, dynamic> verifiedProfileData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/report/generate'), // report routes have /api prefix in python
      headers: {
        'Content-Type': 'application/json',
        'X-API-Key': 'gigcredit-demo-api-key-2026',
      },
      body: jsonEncode(verifiedProfileData),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to generate LLM report');
  }

  @override
  Future<Map<String, dynamic>> getLlmExplanation(Map<String, dynamic> limitsData) {
    throw UnimplementedError();
  }


  @override
  Future<Map<String, dynamic>> checkLoans(String accountNumber) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> verifyVehicle(String vehicleNumber) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> verifyInsurance(String policyNumber, String type) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> verifyPmsym(String pmsymUan) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> verifyItr(String pan, String assessmentYear) {
    throw UnimplementedError();
  }
}
