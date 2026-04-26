import 'api_service.dart';

class RealApiService implements ApiService {
  final String baseUrl;
  RealApiService({this.baseUrl = 'http://10.0.2.2:8000/api'});
  @override
  Future<Map<String, dynamic>> sendOtp(String mobile, {bool isSignup = false}) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> verifyOtp(String mobile, String otp) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> verifyAadhaar(String aadhaarNumber) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> verifyPan(String panNumber) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> verifyAccount(String accountNo, String ifsc) {
    throw UnimplementedError();
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
  Future<Map<String, dynamic>> generateReportScore(Map<String, dynamic> verifiedProfileData) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> getLlmExplanation(Map<String, dynamic> limitsData) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> verifyIfsc(String ifsc) {
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
