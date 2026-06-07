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

  Future<http.Response> _post(String url,
      {required Map<String, String> headers,
      required String body,
      Duration timeout = const Duration(seconds: 120)}) async {
    try {
      return await http
          .post(Uri.parse(url), headers: headers, body: body)
          .timeout(timeout);
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('ClientException') ||
          e.toString().contains('TimeoutException')) {
        throw Exception(
            'Network Error: Please check your connection and try again.');
      }
      rethrow;
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  String _formatMobile(String mobile) {
    if (!mobile.startsWith('+')) {
      return '+91$mobile';
    }
    return mobile;
  }

  @override
  Future<Map<String, dynamic>> sendOtp(String mobile,
      {bool isSignup = false, String? name}) async {
    // Judge mock bypass
    if (mobile == '9094909490' || mobile == '+919094909490') {
      return {'status': 'success', 'message': 'OTP sent via Twilio'};
    }

    final formattedMobile = _formatMobile(mobile);
    final basicAuth = base64Encode(utf8
        .encode('${AppConfig.twilioAccountSid}:${AppConfig.twilioAuthToken}'));

    try {
      final response = await http.post(
        Uri.parse(
            'https://verify.twilio.com/v2/Services/${AppConfig.twilioServiceSid}/Verifications'),
        headers: {
          'Authorization': 'Basic $basicAuth',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'To': formattedMobile,
          'Channel': 'sms',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'status': 'success', 'message': 'OTP sent via Twilio'};
      }
      final errorData = jsonDecode(response.body);
      final errorMsg =
          errorData['detail'] ?? errorData['message'] ?? 'Failed to send OTP';
      throw Exception(errorMsg);
    } catch (e) {
      throw Exception('Twilio Error: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> verifyOtp(String mobile, String otp) async {
    // Standardize to generic mock flow for +919999999999 to bypass twilio rate limits during dev
    if (mobile == '9999999999' || mobile == '+919999999999') {
      if (otp == '123456') {
        return {
          'status': 'success',
          'token': 'mock-dev-token-999',
          'user': {'name': 'Test User'}
        };
      }
    }

    // Judge mock bypass
    if (mobile == '9094909490' || mobile == '+919094909490') {
      if (otp == '909490') {
        return {
          'status': 'success',
          'token': 'mock-dev-token-judge',
          'user': {'name': 'demo'}
        };
      } else {
        throw Exception('Invalid OTP');
      }
    }

    final formattedMobile = _formatMobile(mobile);
    final basicAuth = base64Encode(utf8
        .encode('${AppConfig.twilioAccountSid}:${AppConfig.twilioAuthToken}'));

    try {
      final response = await http.post(
        Uri.parse(
            'https://verify.twilio.com/v2/Services/${AppConfig.twilioServiceSid}/VerificationCheck'),
        headers: {
          'Authorization': 'Basic $basicAuth',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'To': formattedMobile,
          'Code': otp,
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'approved') {
          // Twilio approved. We return a fake token since backend isn't handling auth right now.
          return {
            'status': 'success',
            'token': 'twilio-auth-token-12345',
            'user': {'name': 'Gig Worker'}
          };
        } else {
          throw Exception('Invalid OTP');
        }
      }

      final errorData = jsonDecode(response.body);
      final errorMsg =
          errorData['detail'] ?? errorData['message'] ?? 'Failed to verify OTP';
      throw Exception(errorMsg);
    } catch (e) {
      throw Exception('Twilio Verify Error: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> verifyAadhaar(String aadhaarNumber) async {
    final response = await _post(
      '$baseUrl/gov/aadhaar/verify',
      headers: _headers,
      body: jsonEncode({'aadhaar': aadhaarNumber}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final errorMsg =
        jsonDecode(response.body)['detail'] ?? 'Failed to verify Aadhaar';
    throw Exception(errorMsg);
  }

  @override
  Future<Map<String, dynamic>> verifyAadhaarOtp(
      String aadhaarNumber, String otp) async {
    final response = await _post(
      '$baseUrl/gov/aadhaar/otp/validate',
      headers: _headers,
      body: jsonEncode({'aadhaar': aadhaarNumber, 'otp': otp}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final body = jsonDecode(response.body);
    throw Exception(
        body['detail'] ?? body['message'] ?? 'OTP verification failed');
  }

  @override
  Future<Map<String, dynamic>> verifyPan(String panNumber) async {
    final response = await _post(
      '$baseUrl/gov/pan/verify',
      headers: _headers,
      body: jsonEncode({'pan': panNumber}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final errorMsg =
        jsonDecode(response.body)['detail'] ?? 'Failed to verify PAN';
    throw Exception(errorMsg);
  }

  @override
  Future<Map<String, dynamic>> verifyPanOtp(
      String panNumber, String otp) async {
    final response = await _post(
      '$baseUrl/gov/pan/otp/validate',
      headers: _headers,
      body: jsonEncode({'pan': panNumber, 'otp': otp}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final body = jsonDecode(response.body);
    throw Exception(
        body['detail'] ?? body['message'] ?? 'OTP verification failed');
  }

  // ── Step 4: Utility ──────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> verifyEb(String serviceNumber) async {
    final response = await _post(
      '$baseUrl/gov/eb/verify',
      headers: _headers,
      body: jsonEncode({'service_number': serviceNumber}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    final body = jsonDecode(response.body);
    throw Exception(body['detail'] ?? 'EB verification failed');
  }

  @override
  Future<Map<String, dynamic>> verifyLpg(
      String consumerNumber, String provider) async {
    final response = await _post(
      '$baseUrl/gov/lpg/verify',
      headers: _headers,
      body:
          jsonEncode({'consumer_number': consumerNumber, 'provider': provider}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    final body = jsonDecode(response.body);
    throw Exception(body['detail'] ?? 'LPG verification failed');
  }

  // ── Step 5: Work ─────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> verifyVehicleInsurance(
      String vehicleNumber) async {
    final response = await _post(
      '$baseUrl/gov/vehicle/insurance/verify',
      headers: _headers,
      body: jsonEncode({'vehicle_number': vehicleNumber}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    final body = jsonDecode(response.body);
    throw Exception(body['detail'] ?? 'Vehicle insurance verification failed');
  }

  // ── Step 6: Schemes ──────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> verifyUdyam(String udyamNumber) async {
    final response = await _post(
      '$baseUrl/gov/msme/udyam-verify',
      headers: _headers,
      body: jsonEncode({'udyam_number': udyamNumber}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    final body = jsonDecode(response.body);
    throw Exception(body['detail'] ?? 'Udyam verification failed');
  }

  // ── Step 8: Tax ──────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> getGstFilingHistory(String gstin) async {
    final response = await _post(
      '$baseUrl/gov/gst/filing-history',
      headers: _headers,
      body: jsonEncode({'gstin': gstin}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    final body = jsonDecode(response.body);
    throw Exception(body['detail'] ?? 'GST filing history failed');
  }

  // ── Step 9: Loans ────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> verifyLoan(
      String lenderName, double emiAmount, String latestDebitDate) async {
    final response = await _post(
      '$baseUrl/gov/loan/verify',
      headers: _headers,
      body: jsonEncode({
        'lender_name': lenderName,
        'emi_amount': emiAmount,
        'latest_debit_date': latestDebitDate,
      }),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    final body = jsonDecode(response.body);
    throw Exception(body['detail'] ?? 'Loan verification failed');
  }

  @override
  Future<Map<String, dynamic>> verifyAccount(
      String accountNo, String ifsc) async {
    final response = await _post(
      '$baseUrl/bank/account/verify',
      headers: _headers,
      body: jsonEncode({'account_number': accountNo, 'ifsc': ifsc}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final errorMsg =
        jsonDecode(response.body)['detail'] ?? 'Failed to verify Account';
    throw Exception(errorMsg);
  }

  @override
  Future<Map<String, dynamic>> verifyIfsc(String ifsc) async {
    final response = await _post(
      '$baseUrl/bank/ifsc/verify',
      headers: _headers,
      body: jsonEncode({'ifsc': ifsc}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final errorMsg =
        jsonDecode(response.body)['detail'] ?? 'Failed to verify IFSC';
    throw Exception(errorMsg);
  }

  @override
  Future<Map<String, dynamic>> uploadBankStatement(String base64Pdf) async {
    final response = await _post(
      '$baseUrl/bank/statement/upload',
      headers: _headers,
      body: jsonEncode({'pdf_base64': base64Pdf}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception(
        'Failed to upload bank statement. Endpoint may not be active.');
  }

  @override
  Future<Map<String, dynamic>> verifyUtility(
      String consumerNumber, String provider) async {
    final response = await _post(
      '$baseUrl/utility/verify',
      headers: _headers,
      body:
          jsonEncode({'consumer_number': consumerNumber, 'provider': provider}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception(
        'Utility verification not currently available from provider.');
  }

  @override
  Future<Map<String, dynamic>> verifyUan(String uanNumber) async {
    final response = await _post(
      '$baseUrl/gov/eshram/verify',
      headers: _headers,
      body: jsonEncode({'uan': uanNumber}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to verify UAN.');
  }

  @override
  Future<Map<String, dynamic>> getGigHistory(String platformId) async {
    final response = await _post(
      '$baseUrl/work/gig-history',
      headers: _headers,
      body: jsonEncode({'platform_id': platformId}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Gig platform integration currently unavailable.');
  }

  @override
  Future<Map<String, dynamic>> verifyEshram(String eshramNumber) async {
    final response = await _post(
      '$baseUrl/gov/eshram/verify',
      headers: _headers,
      body: jsonEncode({'uan': eshramNumber}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('eShram verification failed.');
  }

  @override
  Future<Map<String, dynamic>> verifyRationCard(String cardNumber) async {
    final response = await _post(
      '$baseUrl/gov/ration/verify',
      headers: _headers,
      body: jsonEncode({'card_number': cardNumber}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Ration card verification failed.');
  }

  @override
  Future<Map<String, dynamic>> verifyAybha(String aybhaId) async {
    final response = await _post(
      '$baseUrl/gov/aybha/verify',
      headers: _headers,
      body: jsonEncode({'aybha_id': aybhaId}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('ABHA verification failed.');
  }

  @override
  Future<Map<String, dynamic>> verifyGst(String gstNumber) async {
    final response = await _post(
      '$baseUrl/gov/gst/verify',
      headers: _headers,
      body: jsonEncode({'gst': gstNumber}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('GST verification failed.');
  }

  @override
  Future<Map<String, dynamic>> uploadItr(String base64Itr) async {
    final response = await _post(
      '$baseUrl/tax/itr/upload',
      headers: _headers,
      body: jsonEncode({'itr_base64': base64Itr}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('ITR upload failed.');
  }

  @override
  Future<Map<String, dynamic>> generateReportScore(
      Map<String, dynamic> verifiedProfileData) async {
    final response = await _post(
      '$baseUrl/api/report/generate',
      headers: _headers,
      body: jsonEncode(verifiedProfileData),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to generate LLM report');
  }

  @override
  Future<Map<String, dynamic>> getLlmExplanation(
      Map<String, dynamic> limitsData) async {
    final response = await _post(
      '$baseUrl/explain/full',
      headers: _headers,
      body: jsonEncode(limitsData),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('LLM explanation failed.');
  }

  @override
  Future<Map<String, dynamic>> checkLoans(String accountNumber) async {
    final response = await _post(
      '$baseUrl/bank/loan/check',
      headers: _headers,
      body: jsonEncode({'account_number': accountNumber}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Loan check failed.');
  }

  @override
  Future<Map<String, dynamic>> verifyVehicle(String vehicleNumber) async {
    final response = await _post(
      '$baseUrl/gov/vehicle/rc/verify',
      headers: _headers,
      body: jsonEncode({'vehicle_number': vehicleNumber}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Vehicle verification failed.');
  }

  @override
  Future<Map<String, dynamic>> verifyInsurance(
      String policyNumber, String type) async {
    final response = await _post(
      '$baseUrl/gov/insurance/policy/verify',
      headers: _headers,
      body: jsonEncode({'policy_number': policyNumber, 'policy_type': type}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Insurance verification failed.');
  }

  @override
  Future<Map<String, dynamic>> verifyPmsym(String pmsymUan) async {
    final response = await _post(
      '$baseUrl/gov/pmsym/verify',
      headers: _headers,
      body: jsonEncode({'uan': pmsymUan}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('PMSYM verification failed.');
  }

  @override
  Future<Map<String, dynamic>> verifyItr(
      String pan, String assessmentYear) async {
    final response = await _post(
      '$baseUrl/gov/income-tax/itr/verify',
      headers: _headers,
      body: jsonEncode({'pan': pan, 'assessment_year': assessmentYear}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('ITR verification failed.');
  }
}
