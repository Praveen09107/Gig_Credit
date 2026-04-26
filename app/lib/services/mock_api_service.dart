import 'api_service.dart';

class MockApiService implements ApiService {
  Future<void> _delay() async {
    await Future.delayed(const Duration(milliseconds: 1500));
  }

  @override
  Future<Map<String, dynamic>> sendOtp(String mobile, {bool isSignup = false}) async {
    await _delay();
    return {'status': 'success', 'message': 'OTP sent successfully'};
  }

  @override
  Future<Map<String, dynamic>> verifyOtp(String mobile, String otp) async {
    await _delay();
    if (otp == '000000') {
      return {'status': 'success', 'token': 'mock_jwt_token', 'user': {'name': 'Praveen Kumar', 'mobile': mobile}};
    }
    throw Exception('Invalid OTP');
  }

  @override
  Future<Map<String, dynamic>> verifyAadhaar(String aadhaarNumber) async {
    await _delay();
    return {
      'verified': true,
      'name': 'Praveen K',
      'yob': '1995',
      'confidence': 0.98,
    };
  }

  @override
  Future<Map<String, dynamic>> verifyPan(String panNumber) async {
    await _delay();
    return {
      'verified': true,
      'name': 'PRAVEEN K',
      'linked_aadhaar': true,
      'confidence': 0.95,
    };
  }

  @override
  Future<Map<String, dynamic>> verifyAccount(String accountNo, String ifsc) async {
    await _delay();
    return {
      'verified': true,
      'account_match': true,
      'bank_name': 'HDFC Bank',
      'confidence': 0.90,
    };
  }

  @override
  Future<Map<String, dynamic>> uploadBankStatement(String base64Pdf) async {
    await _delay();
    return {
      'parsed': true,
      'average_balance': 15000.0,
      'inflow_count': 12,
      'outflow_count': 20,
    };
  }

  @override
  Future<Map<String, dynamic>> verifyUtility(String consumerNumber, String provider) async {
    await _delay();
    return {
      'verified': true,
      'address_match': true,
      'late_payments': 0,
      'confidence': 0.85,
    };
  }

  @override
  Future<Map<String, dynamic>> verifyUan(String uanNumber) async {
    await _delay();
    return {
      'verified': true,
      'balance': 25000.0,
      'last_contribution': '2023-10-05',
    };
  }

  @override
  Future<Map<String, dynamic>> getGigHistory(String platformId) async {
    await _delay();
    return {
      'verified': true,
      'tenure_months': 24,
      'rating': 4.8,
      'monthly_avg': 18000.0,
    };
  }

  @override
  Future<Map<String, dynamic>> verifyEshram(String eshramNumber) async {
    await _delay();
    return {
      'verified': true,
      'occupation': 'Driver',
    };
  }

  @override
  Future<Map<String, dynamic>> verifyRationCard(String cardNumber) async {
    await _delay();
    return {
      'verified': true,
      'family_size': 4,
    };
  }

  @override
  Future<Map<String, dynamic>> verifyAybha(String aybhaId) async {
    await _delay();
    return {
      'verified': true,
      'active': true,
    };
  }

  @override
  Future<Map<String, dynamic>> verifyGst(String gstNumber) async {
    await _delay();
    return {
      'verified': true,
      'filing_status': 'Regular',
    };
  }

  @override
  Future<Map<String, dynamic>> uploadItr(String base64Itr) async {
    await _delay();
    return {
      'parsed': true,
      'gross_income': 450000.0,
      'tax_paid': 0.0,
    };
  }

  @override
  Future<Map<String, dynamic>> generateReportScore(Map<String, dynamic> verifiedData) async {
    await _delay();
    return {
      'score': 745,
      'grade': 'A',
      'proof_id': 'TXN-${DateTime.now().millisecondsSinceEpoch}',
    };
  }

  @override
  Future<Map<String, dynamic>> getLlmExplanation(Map<String, dynamic> limitsData) async {
    await Future.delayed(const Duration(seconds: 2));
    return {
      'text': 'Your score of 745 indicates an **Excellent** credit profile. Your consistent income and zero defaults are strong positives. Limiting credit inquiries and maintaining moderate utilization will further improve your score over time.',
    };
  }

  // ── New Methods (Plan-Complete) ──

  @override
  Future<Map<String, dynamic>> verifyIfsc(String ifsc) async {
    await _delay();
    return {
      'valid': true,
      'bank_name': 'HDFC Bank',
      'branch': 'Anna Nagar, Chennai',
      'city': 'Chennai',
    };
  }

  @override
  Future<Map<String, dynamic>> checkLoans(String accountNumber) async {
    await _delay();
    return {
      'active_loans': 1,
      'total_outstanding': 45000.0,
      'monthly_emi': 2500.0,
      'lender': 'Bajaj Finserv',
    };
  }

  @override
  Future<Map<String, dynamic>> verifyVehicle(String vehicleNumber) async {
    await _delay();
    return {
      'verified': true,
      'owner_name': 'Praveen Kumar',
      'vehicle_type': 'Two Wheeler',
      'registration_valid': true,
      'insurance_active': true,
    };
  }

  @override
  Future<Map<String, dynamic>> verifyInsurance(String policyNumber, String type) async {
    await _delay();
    return {
      'verified': true,
      'type': type,
      'provider': type == 'health' ? 'HDFC Ergo' : (type == 'vehicle' ? 'ICICI Lombard' : 'LIC'),
      'status': 'Active',
      'premium_paid': true,
    };
  }

  @override
  Future<Map<String, dynamic>> verifyPmsym(String pmsymUan) async {
    await _delay();
    return {
      'verified': true,
      'scheme': 'PM Shram Yogi Maan-dhan',
      'enrolled': true,
    };
  }

  @override
  Future<Map<String, dynamic>> verifyItr(String pan, String assessmentYear) async {
    await _delay();
    return {
      'verified': true,
      'pan': pan,
      'assessment_year': assessmentYear,
      'total_income': 340000,
      'tax_paid': 12500,
      'filing_date': '2025-07-28',
    };
  }
}

