import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../core/config/app_config.dart';

class RealApiService implements ApiService {
  final String baseUrl = AppConfig.baseUrl;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'X-API-Key': AppConfig.apiKey,
  };

  @override
  Future<Map<String, dynamic>> sendOtp(String mobile, {bool isSignup = false, String? name}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/otp/send'),
      headers: _headers,
      body: jsonEncode({'mobile': mobile, 'isSignup': isSignup, 'name': name}),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final errorMsg = jsonDecode(response.body)['detail'] ?? 'Failed to send OTP';
    throw Exception(errorMsg);
  }

  @override
  Future<Map<String, dynamic>> verifyOtp(String mobile, String otp) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/otp/verify'),
      headers: _headers,
      body: jsonEncode({'mobile': mobile, 'otp': otp}),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final errorMsg = jsonDecode(response.body)['detail'] ?? 'Invalid OTP';
    throw Exception(errorMsg);
  }

  @override
  Future<Map<String, dynamic>> verifyAadhaar(String aadhaarNumber) async {
    final response = await http.post(
      Uri.parse('$baseUrl/gov/aadhaar/verify'),
      headers: _headers,
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
      headers: _headers,
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
      headers: _headers,
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
      headers: _headers,
      body: jsonEncode({'ifsc': ifsc}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final errorMsg = jsonDecode(response.body)['detail'] ?? 'Failed to verify IFSC';
    throw Exception(errorMsg);
  }

  @override
  Future<Map<String, dynamic>> uploadBankStatement(String base64Pdf) async {
    final response = await http.post(
      Uri.parse('$baseUrl/bank/statement/upload'),
      headers: _headers,
      body: jsonEncode({'pdf_base64': base64Pdf}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to upload bank statement. Endpoint may not be active.');
  }

  @override
  Future<Map<String, dynamic>> verifyUtility(String consumerNumber, String provider) async {
    final response = await http.post(
      Uri.parse('$baseUrl/utility/verify'),
      headers: _headers,
      body: jsonEncode({'consumer_number': consumerNumber, 'provider': provider}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Utility verification not currently available from provider.');
  }

  @override
  Future<Map<String, dynamic>> verifyUan(String uanNumber) async {
    final response = await http.post(
      Uri.parse('$baseUrl/gov/uan/verify'),
      headers: _headers,
      body: jsonEncode({'uan': uanNumber}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to verify UAN.');
  }

  @override
  Future<Map<String, dynamic>> getGigHistory(String platformId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/work/gig-history'),
      headers: _headers,
      body: jsonEncode({'platform_id': platformId}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Gig platform integration currently unavailable.');
  }

  @override
  Future<Map<String, dynamic>> verifyEshram(String eshramNumber) async {
    final response = await http.post(
      Uri.parse('$baseUrl/gov/eshram/verify'),
      headers: _headers,
      body: jsonEncode({'eshram': eshramNumber}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('eShram verification failed.');
  }

  @override
  Future<Map<String, dynamic>> verifyRationCard(String cardNumber) async {
    final response = await http.post(
      Uri.parse('$baseUrl/gov/ration/verify'),
      headers: _headers,
      body: jsonEncode({'card_number': cardNumber}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Ration card verification failed.');
  }

  @override
  Future<Map<String, dynamic>> verifyAybha(String aybhaId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/gov/aybha/verify'),
      headers: _headers,
      body: jsonEncode({'aybha_id': aybhaId}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('ABHA verification failed.');
  }

  @override
  Future<Map<String, dynamic>> verifyGst(String gstNumber) async {
    final response = await http.post(
      Uri.parse('$baseUrl/gov/gst/verify'),
      headers: _headers,
      body: jsonEncode({'gst': gstNumber}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('GST verification failed.');
  }

  @override
  Future<Map<String, dynamic>> uploadItr(String base64Itr) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tax/itr/upload'),
      headers: _headers,
      body: jsonEncode({'itr_base64': base64Itr}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('ITR upload failed.');
  }

  @override
  Future<Map<String, dynamic>> generateReportScore(Map<String, dynamic> verifiedProfileData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/report/generate'),
      headers: _headers,
      body: jsonEncode(verifiedProfileData),
    ).timeout(const Duration(seconds: 60));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to generate LLM report');
  }

  @override
  Future<Map<String, dynamic>> getLlmExplanation(Map<String, dynamic> limitsData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/explain/llm'),
      headers: _headers,
      body: jsonEncode(limitsData),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('LLM explanation failed.');
  }

  @override
  Future<Map<String, dynamic>> checkLoans(String accountNumber) async {
    final response = await http.post(
      Uri.parse('$baseUrl/bank/loans/check'),
      headers: _headers,
      body: jsonEncode({'account_number': accountNumber}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Loan check failed.');
  }

  @override
  Future<Map<String, dynamic>> verifyVehicle(String vehicleNumber) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transport/vehicle/verify'),
      headers: _headers,
      body: jsonEncode({'vehicle_number': vehicleNumber}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Vehicle verification failed.');
  }

  @override
  Future<Map<String, dynamic>> verifyInsurance(String policyNumber, String type) async {
    final response = await http.post(
      Uri.parse('$baseUrl/insurance/verify'),
      headers: _headers,
      body: jsonEncode({'policy_number': policyNumber, 'type': type}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Insurance verification failed.');
  }

  @override
  Future<Map<String, dynamic>> verifyPmsym(String pmsymUan) async {
    final response = await http.post(
      Uri.parse('$baseUrl/gov/pmsym/verify'),
      headers: _headers,
      body: jsonEncode({'pmsym_uan': pmsymUan}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('PMSYM verification failed.');
  }

  @override
  Future<Map<String, dynamic>> verifyItr(String pan, String assessmentYear) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tax/itr/verify'),
      headers: _headers,
      body: jsonEncode({'pan': pan, 'assessment_year': assessmentYear}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('ITR verification failed.');
  }
}
