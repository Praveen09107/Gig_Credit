// ignore_for_file: avoid_print
/// ─────────────────────────────────────────────────────────────────────────────
/// INTEGRATION TEST: Cross-Validation Pipeline with Real Document Data
///
/// Tests the identity chain + bank cross-verification using actual OCR data
/// extracted from Praveen Kumar P's Aadhaar, PAN, and Bank Statement.
///
/// Run: dart run bin/test_cross_validation.dart
/// ─────────────────────────────────────────────────────────────────────────────
import '../lib/scoring/validation/fuzzy_matcher.dart';
import '../lib/scoring/validation/step1_validator.dart';
import '../lib/scoring/validation/step2_validator.dart';
import '../lib/scoring/validation/step3_validator.dart';
import '../lib/scoring/validation/bank_transaction_matcher.dart';
import '../lib/scoring/validation/cross_step_validator.dart';

void main() {
  print('');
  print('╔══════════════════════════════════════════════════════════════╗');
  print('║  GIGCREDIT CROSS-VALIDATION PIPELINE — INTEGRATION TEST    ║');
  print('║  Using real document data from Praveen Kumar P             ║');
  print('╚══════════════════════════════════════════════════════════════╝');
  print('');

  // ═══════════════════════════════════════════════════════════════════════
  // DOCUMENT DATA (Extracted from real images)
  // ═══════════════════════════════════════════════════════════════════════
  const aadhaarName    = 'Praveen Kumar P';
  const aadhaarDob     = '09/01/2007';
  const aadhaarNumber  = '749420067990';
  const aadhaarFather  = 'Prabhakaran';
  const aadhaarAddress = 'S/O: Prabhakaran, 205F, SRIRANGAM NEW TOWN, WIMCO NAGAR, SAKTHIPURAM, Kattivakkam, Tiruvallur, Tamil Nadu, 600057';

  const panName        = 'PRAVEEN KUMAR P';
  const panFather      = 'PRABAKARAN';
  const panNumber      = 'IPZPP3254R';
  const panDob         = '09/01/2007';

  // Step 1 personal info (simulated user input)
  const step1Name      = 'Praveen Kumar P';
  const step1Dob       = '09/01/2007';
  const step1Income    = 25000.0; // ₹25k/month declared
  const step1Age       = 18;
  const step1WorkType  = 'gig_worker';

  // Bank statement holder (simulated from OCR)
  const bankHolder     = 'PRAVEEN KUMAR P';
  const bankIfsc       = 'SBIN0001234';
  const bankAccount    = '39876543210';

  // ═══════════════════════════════════════════════════════════════════════
  // TEST 1: Step 1 Validation
  // ═══════════════════════════════════════════════════════════════════════
  print('─── TEST 1: Step 1 Personal Info Validation ──────────────────');
  final step1Result = Step1Validator.validate(
    fullName: step1Name,
    dateOfBirth: step1Dob,
    selfDeclaredIncome: step1Income,
    workType: step1WorkType,
    mobileNumber: '9876543210',
    currentAddress: '205F, Srirangam New Town, Chennai',
    permanentAddress: '205F, Srirangam New Town, Chennai',
    stateOfResidence: 'Tamil Nadu',
    yearsInProfession: 2,
    dependents: 0,
    vehicleOwnership: true,
    sameAddress: true,
  );
  print('  Passed: ${step1Result.passed}');
  print('  Issues: ${step1Result.issues.length}');
  for (final i in step1Result.issues) {
    print('    [${i.severity.name}] ${i.code}: ${i.message}');
  }
  print('');

  // ═══════════════════════════════════════════════════════════════════════
  // TEST 2: Aadhaar Format Validation
  // ═══════════════════════════════════════════════════════════════════════
  print('─── TEST 2: Aadhaar Format Validation ────────────────────────');
  final aadhaarIssue = Step2Validator.validateAadhaarFormat(aadhaarNumber);
  print('  Aadhaar: $aadhaarNumber');
  print('  Valid: ${aadhaarIssue == null}');
  if (aadhaarIssue != null) {
    print('  Issue: ${aadhaarIssue.message}');
  }
  print('');

  // ═══════════════════════════════════════════════════════════════════════
  // TEST 3: PAN Format Validation
  // ═══════════════════════════════════════════════════════════════════════
  print('─── TEST 3: PAN Format Validation ────────────────────────────');
  final panIssue = Step2Validator.validatePanFormat(panNumber);
  print('  PAN: $panNumber');
  print('  Valid: ${panIssue == null}');
  if (panIssue != null) {
    print('  Issue: ${panIssue.message}');
  }
  print('');

  // ═══════════════════════════════════════════════════════════════════════
  // TEST 4: IDENTITY CHAIN — Fuzzy Name Matching
  // ═══════════════════════════════════════════════════════════════════════
  print('─── TEST 4: Identity Chain — Name Cross-Matching ─────────────');

  final pairs = [
    ['Step1 ↔ Aadhaar', step1Name, aadhaarName],
    ['Step1 ↔ PAN', step1Name, panName],
    ['Aadhaar ↔ PAN', aadhaarName, panName],
    ['Aadhaar ↔ Bank', aadhaarName, bankHolder],
    ['Step1 ↔ Bank', step1Name, bankHolder],
    ['PAN ↔ Bank', panName, bankHolder],
  ];

  for (final pair in pairs) {
    final label = pair[0];
    final name1 = pair[1];
    final name2 = pair[2];
    final match = FuzzyMatcher.matchNames(name1, name2);
    final pct = (match.score * 100).toStringAsFixed(1);
    final icon = match.severity == MatchSeverity.pass ? '✅'
               : match.severity == MatchSeverity.softFlag ? '⚠️'
               : '❌';
    print('  $icon $label: "$name1" vs "$name2" → ${pct}% [${match.severity.name}]');
  }
  print('');

  // ═══════════════════════════════════════════════════════════════════════
  // TEST 5: DOB Chain
  // ═══════════════════════════════════════════════════════════════════════
  print('─── TEST 5: Identity Chain — DOB Cross-Check ─────────────────');
  print('  Step 1 DOB : $step1Dob');
  print('  Aadhaar DOB: $aadhaarDob');
  print('  PAN DOB    : $panDob');
  print('  Match: ${step1Dob == aadhaarDob && aadhaarDob == panDob ? '✅ ALL MATCH' : '❌ MISMATCH'}');
  print('');

  // ═══════════════════════════════════════════════════════════════════════
  // TEST 6: Father Name Cross-Check
  // ═══════════════════════════════════════════════════════════════════════
  print('─── TEST 6: Father Name Cross-Check ──────────────────────────');
  final fatherMatch = FuzzyMatcher.matchNames(aadhaarFather, panFather);
  print('  Aadhaar: "$aadhaarFather" vs PAN: "$panFather"');
  print('  Score: ${(fatherMatch.score * 100).toStringAsFixed(1)}% [${fatherMatch.severity.name}]');
  print('');

  // ═══════════════════════════════════════════════════════════════════════
  // TEST 7: Step 3 Bank Validation
  // ═══════════════════════════════════════════════════════════════════════
  print('─── TEST 7: Step 3 Bank Format Validation ────────────────────');
  final ifscIssue = Step3Validator.validateIfscFormat(bankIfsc);
  final accIssue  = Step3Validator.validateAccountFormat(bankAccount);
  final holderIssue = Step3Validator.validateHolderVsAadhaar(bankHolder, aadhaarName);

  print('  IFSC: $bankIfsc → ${ifscIssue == null ? '✅ Valid' : '❌ ${ifscIssue.message}'}');
  print('  Account: $bankAccount → ${accIssue == null ? '✅ Valid' : '❌ ${accIssue.message}'}');
  print('  Holder vs Aadhaar: ${holderIssue == null ? '✅ Pass' : '⚠️ ${holderIssue.message}'}');
  print('');

  // ═══════════════════════════════════════════════════════════════════════
  // TEST 8: Transaction Categorization
  // ═══════════════════════════════════════════════════════════════════════
  print('─── TEST 8: Transaction Categorization ───────────────────────');
  final sampleTransactions = [
    {'date': '2025-01-05', 'amount': 12500.0, 'type': 'credit', 'description': 'UPI/SWIGGY/PAYOUT/Jan2025'},
    {'date': '2025-01-07', 'amount': 8200.0, 'type': 'credit', 'description': 'NEFT/ZOMATO DELIVERY/WEEKLY'},
    {'date': '2025-01-10', 'amount': 1250.0, 'type': 'debit', 'description': 'TANGEDCO EB BILL PAYMENT'},
    {'date': '2025-01-12', 'amount': 499.0, 'type': 'debit', 'description': 'AIRTEL MOBILE RECHARGE'},
    {'date': '2025-01-15', 'amount': 8000.0, 'type': 'debit', 'description': 'RENT PAYMENT TO LANDLORD'},
    {'date': '2025-01-18', 'amount': 3500.0, 'type': 'debit', 'description': 'BAJAJ FINSERV EMI PAYMENT'},
    {'date': '2025-01-20', 'amount': 1200.0, 'type': 'debit', 'description': 'LIC PREMIUM DEBIT'},
    {'date': '2025-01-22', 'amount': 2000.0, 'type': 'credit', 'description': 'DBT PMJDY CREDIT'},
    {'date': '2025-01-25', 'amount': 199.0, 'type': 'debit', 'description': 'NETFLIX SUBSCRIPTION'},
    {'date': '2025-02-05', 'amount': 13000.0, 'type': 'credit', 'description': 'UPI/SWIGGY/PAYOUT/Feb2025'},
    {'date': '2025-02-10', 'amount': 1300.0, 'type': 'debit', 'description': 'TANGEDCO EB BILL PAYMENT'},
    {'date': '2025-02-12', 'amount': 499.0, 'type': 'debit', 'description': 'JIO POSTPAID BILL'},
    {'date': '2025-02-15', 'amount': 8000.0, 'type': 'debit', 'description': 'RENT TRANSFER MONTHLY'},
    {'date': '2025-02-18', 'amount': 3500.0, 'type': 'debit', 'description': 'BAJAJ FINSERV EMI DEBIT'},
    {'date': '2025-02-20', 'amount': 1200.0, 'type': 'debit', 'description': 'LIC INSURANCE PREMIUM'},
    {'date': '2025-03-05', 'amount': 11800.0, 'type': 'credit', 'description': 'NEFT/UBER/DRIVER PAYOUT'},
    {'date': '2025-03-10', 'amount': 1280.0, 'type': 'debit', 'description': 'ELECTRICITY BILL EB'},
    {'date': '2025-03-18', 'amount': 3500.0, 'type': 'debit', 'description': 'BAJAJ FINSERV EMI'},
  ];

  final categorized = TransactionCategorizer.categorize(sampleTransactions);

  // Count categories
  final catCounts = <String, int>{};
  for (final t in categorized) {
    catCounts[t.category.name] = (catCounts[t.category.name] ?? 0) + 1;
  }
  print('  Total transactions: ${categorized.length}');
  catCounts.forEach((cat, count) {
    print('    $cat: $count');
  });
  print('');

  // ═══════════════════════════════════════════════════════════════════════
  // TEST 9: Utility Bill Cross-Verification
  // ═══════════════════════════════════════════════════════════════════════
  print('─── TEST 9: Utility Bill vs Bank Cross-Verification ──────────');
  final matcher = BankTransactionMatcher(categorized);

  final utilityBills = [
    {'type': 'electricity', 'amount': 1280.0},
    {'type': 'mobile', 'amount': 499.0},
    {'type': 'rent', 'amount': 8000.0},
  ];

  final utilityResult = matcher.verifyUtilityBills(utilityBills);
  print('  Total bills: ${utilityResult.totalItems}');
  print('  Matched: ${utilityResult.matchedItems}');
  print('  Match ratio: ${(utilityResult.matchRatio * 100).toStringAsFixed(0)}%');
  for (final item in utilityResult.items) {
    print('    [${item.status}] ${item.label}: ₹${item.declaredAmount} → ${item.matchResult.matchType} (${(item.matchResult.confidence * 100).toStringAsFixed(0)}%)');
  }
  print('');

  // ═══════════════════════════════════════════════════════════════════════
  // TEST 10: EMI Cross-Verification + Undisclosed EMI Detection
  // ═══════════════════════════════════════════════════════════════════════
  print('─── TEST 10: EMI Cross-Verification + Undisclosed Detection ──');
  final declaredEmis = [
    {'type': 'Bajaj Finserv', 'amount': 3500.0},
  ];
  final emiResult = matcher.verifyEmiPayments(declaredEmis);
  print('  Declared EMIs: ${declaredEmis.length}');
  print('  Matched: ${emiResult.matchedItems}/${emiResult.totalItems}');
  for (final item in emiResult.items) {
    print('    [${item.status}] ${item.label}: ₹${item.declaredAmount} → ${item.matchResult.matchType}');
  }
  for (final w in emiResult.warnings) {
    print('    ⚠ $w');
  }
  print('');

  // ═══════════════════════════════════════════════════════════════════════
  // TEST 11: ITR Income vs Bank Income
  // ═══════════════════════════════════════════════════════════════════════
  print('─── TEST 11: ITR Income vs Bank Cross-Verification ───────────');
  final itrIncome = 300000.0; // ₹3L declared annual
  final bankMonthly = (12500 + 8200 + 13000 + 11800) / 3.0; // avg monthly gig credits
  final itrCheck = matcher.verifyItrIncome(
    itrAnnualIncome: itrIncome,
    bankAvgMonthlyCredit: bankMonthly,
  );
  print('  ITR Annual: ₹${itrIncome.toStringAsFixed(0)}');
  print('  ITR Monthly: ₹${(itrCheck['itr_monthly'] as double).toStringAsFixed(0)}');
  print('  Bank Monthly: ₹${(itrCheck['bank_monthly'] as double).toStringAsFixed(0)}');
  print('  Ratio: ${((itrCheck['ratio'] as double) * 100).toStringAsFixed(1)}%');
  print('  Within range: ${itrCheck['within_range']}');
  print('  Status: ${itrCheck['status']}');
  print('');

  // ═══════════════════════════════════════════════════════════════════════
  // TEST 12: Full Cross-Step Validation
  // ═══════════════════════════════════════════════════════════════════════
  print('─── TEST 12: Full Cross-Step Identity Chain ──────────────────');
  final ocrResults = {
    'aadhaar_front': {
      'name': aadhaarName,
      'dob': aadhaarDob,
      'aadhaar_number': aadhaarNumber,
      'father_name': aadhaarFather,
      'address': aadhaarAddress,
    },
    'pan': {
      'name': panName,
      'dob': panDob,
      'pan_number': panNumber,
      'father_name': panFather,
    },
    'bank_statement': {
      'holder_name': bankHolder,
      'ifsc_code': bankIfsc,
      'account_number': bankAccount,
      'bank_name': 'State Bank of India',
    },
  };

  final crossIssues = CrossStepValidator.validate(ocrResults);

  print('  Total issues: ${crossIssues.length}');
  final hardFails = crossIssues.where((i) => i.severity == IssueSeverity.error).length;
  final softFlags = crossIssues.where((i) => i.severity == IssueSeverity.warning).length;
  print('  Hard fails: $hardFails');
  print('  Soft flags: $softFlags');
  print('  Chain valid: ${hardFails == 0}');
  for (final issue in crossIssues) {
    final icon = issue.severity == IssueSeverity.error ? '❌'
               : issue.severity == IssueSeverity.warning ? '⚠️'
               : 'ℹ️';
    print('    $icon [${issue.severity.name}] ${issue.title}: ${issue.description}');
  }
  print('');

  // ═══════════════════════════════════════════════════════════════════════
  // SUMMARY
  // ═══════════════════════════════════════════════════════════════════════
  print('╔══════════════════════════════════════════════════════════════╗');
  print('║                    TEST SUMMARY                            ║');
  print('╠══════════════════════════════════════════════════════════════╣');
  print('║  Aadhaar format     : ${aadhaarIssue == null ? "✅ PASS" : "❌ FAIL"}                              ║');
  print('║  PAN format         : ${panIssue == null ? "✅ PASS" : "❌ FAIL"}                              ║');
  print('║  Name chain (6 pairs): All tested                         ║');
  print('║  DOB chain          : ${step1Dob == aadhaarDob ? "✅ PASS" : "❌ FAIL"}                              ║');
  print('║  Bank format        : ${ifscIssue == null && accIssue == null ? "✅ PASS" : "❌ FAIL"}                              ║');
  print('║  Transaction categ. : ${categorized.length} classified                     ║');
  print('║  Utility match      : ${utilityResult.matchedItems}/${utilityResult.totalItems} matched                          ║');
  print('║  EMI match          : ${emiResult.matchedItems}/${emiResult.totalItems} matched                          ║');
  print('║  ITR income check   : ${itrCheck['within_range'] == true ? "✅ PASS" : "⚠️ FLAG"}                              ║');
  print('║  Identity chain     : ${hardFails == 0 ? "✅ VALID" : "❌ INVALID"}                             ║');
  print('╚══════════════════════════════════════════════════════════════╝');
}
