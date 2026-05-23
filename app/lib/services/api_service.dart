abstract class ApiService {
  // Auth
  Future<Map<String, dynamic>> sendOtp(String mobile, {bool isSignup = false, String? name});
  Future<Map<String, dynamic>> verifyOtp(String mobile, String otp);
  
  // Verification (13 Endpoints matching planning doc)
  // KYC
  Future<Map<String, dynamic>> verifyAadhaar(String aadhaarNumber);
  Future<Map<String, dynamic>> verifyAadhaarOtp(String aadhaarNumber, String otp);
  Future<Map<String, dynamic>> verifyPan(String panNumber);
  Future<Map<String, dynamic>> verifyPanOtp(String panNumber, String otp);

  // Step 4 — Utility
  Future<Map<String, dynamic>> verifyEb(String serviceNumber);
  Future<Map<String, dynamic>> verifyLpg(String consumerNumber, String provider);

  // Step 5 — Work
  Future<Map<String, dynamic>> verifyVehicleInsurance(String vehicleNumber);

  // Step 6 — Schemes
  Future<Map<String, dynamic>> verifyUdyam(String udyamNumber);

  // Step 8 — Tax
  Future<Map<String, dynamic>> getGstFilingHistory(String gstin);

  // Step 9 — Loans
  Future<Map<String, dynamic>> verifyLoan(String lenderName, double emiAmount, String latestDebitDate);
  
  // Bank
  Future<Map<String, dynamic>> verifyAccount(String accountNo, String ifsc);
  Future<Map<String, dynamic>> verifyIfsc(String ifsc);
  Future<Map<String, dynamic>> uploadBankStatement(String base64Pdf);
  Future<Map<String, dynamic>> checkLoans(String accountNumber);
  
  // Utility
  Future<Map<String, dynamic>> verifyUtility(String consumerNumber, String provider);
  
  // Work
  Future<Map<String, dynamic>> verifyUan(String uanNumber);
  Future<Map<String, dynamic>> getGigHistory(String platformId);
  Future<Map<String, dynamic>> verifyVehicle(String vehicleNumber);
  
  // Gov/Schemes
  Future<Map<String, dynamic>> verifyEshram(String eshramNumber);
  Future<Map<String, dynamic>> verifyPmsym(String pmsymUan);
  Future<Map<String, dynamic>> verifyRationCard(String cardNumber);
  
  // Insurance/Tax
  Future<Map<String, dynamic>> verifyAybha(String aybhaId);
  Future<Map<String, dynamic>> verifyInsurance(String policyNumber, String type);
  Future<Map<String, dynamic>> verifyGst(String gstNumber);
  Future<Map<String, dynamic>> uploadItr(String base64Itr);
  Future<Map<String, dynamic>> verifyItr(String pan, String assessmentYear);
  
  // Scoring
  Future<Map<String, dynamic>> generateReportScore(Map<String, dynamic> verifiedProfileData);
  Future<Map<String, dynamic>> getLlmExplanation(Map<String, dynamic> limitsData);
}
