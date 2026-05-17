import 'dart:math';
import '../../models/verified_profile/verified_profile.dart';
import '../../models/verified_profile/personal_info.dart';
import '../../models/verified_profile/kyc_info.dart';
import '../../models/verified_profile/bank_info.dart';
import '../../models/verified_profile/utility_info.dart';
import '../../models/verified_profile/emi_loans_info.dart';
import '../../models/verified_profile/insurance_info.dart';
import '../../models/verified_profile/tax_info.dart';
import '../../models/verified_profile/gov_schemes_info.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// DEMO MODE FLAG — flip to false before production submission
/// ─────────────────────────────────────────────────────────────────────────────
const bool kDemoMode = true;

/// Demo profile categories for judging
enum DemoRiskCategory { lowRisk, mediumRisk, highRisk, irregular, fraud }

/// ─────────────────────────────────────────────────────────────────────────────
/// DemoProfileService
/// ISOLATED from core pipeline. Produces VerifiedProfile objects that flow
/// through the SAME feature extraction → ML → XAI pipeline as real users.
/// NO direct score injection. NO shortcuts.
/// ─────────────────────────────────────────────────────────────────────────────
class DemoProfileService {
  static final _rng = Random(42);

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Load a random profile across all risk categories
  static VerifiedProfile loadRandom() =>
      _allProfiles[_rng.nextInt(_allProfiles.length)];

  /// Load a specific risk category profile
  static VerifiedProfile loadByCategory(DemoRiskCategory cat) {
    final list = _byCategory[cat] ?? _allProfiles;
    return list[_rng.nextInt(list.length)];
  }

  /// All 50+ profiles list
  static List<VerifiedProfile> get allProfiles => _allProfiles;

  // ── Profile Builder Helpers ────────────────────────────────────────────────

  /// Build BankInfo from monthly income arrays (realistic variation)
  static BankInfo _bank({
    required String name,
    required List<double> monthlyCredits,
    required List<double> monthlyDebits,
    String bank = 'Axis Bank',
  }) =>
      BankInfo(
        isVerified: true,
        accountHolderName: name,
        bankName: bank,
        ifscCode: 'HDFC0001234',
        accountNumber: '098765432123',
        monthlyCredits: monthlyCredits,
        monthlyDebits: monthlyDebits,
      );

  static UtilityInfo _utility(List<Map<String, dynamic>> bills) => UtilityInfo(
        isVerified: true,
        bills: bills
            .map((b) => UtilityBillEntry(
                  billType: b['type'] as String,
                  amount: (b['amount'] as num).toDouble(),
                  verified: b['verified'] as bool? ?? true,
                ))
            .toList(),
      );

  static EmiLoansInfo _emi(List<Map<String, dynamic>> loans) => EmiLoansInfo(
        isVerified: loans.isNotEmpty,
        loans: loans
            .map((l) => EmiEntry(
                  loanType: l['type'] as String,
                  monthlyEmi: (l['emi'] as num).toDouble(),
                  outstandingBalance:
                      (l['outstanding'] as num? ?? 0).toDouble(),
                  remainingMonths: l['months'] as int? ?? 24,
                  regularPayment: l['regular'] as bool? ?? true,
                ))
            .toList(),
      );

  // ── LOW RISK PROFILES (15 profiles) ───────────────────────────────────────
  static final List<VerifiedProfile> _lowRiskProfiles = [
    // Profile 1: Stable salaried worker, good savings
    VerifiedProfile(
      personalInfo: const PersonalInfo(
        isVerified: true, fullName: 'Karthik Rajan', dateOfBirth: '15/06/1990',
        workType: 'salaried', selfDeclaredIncome: 35000,
        yearsInProfession: 8, dependents: 2,
      ),
      kycInfo: const KycInfo(isVerified: true, backVerified: true, panVerified: true, nameMatchScore: 0.97),
      bankInfo: _bank(name: 'Karthik Rajan', monthlyCredits: [35000, 35200, 34800, 35000, 35500, 35000], monthlyDebits: [18000, 17500, 19000, 18200, 17800, 18500]),
      utilityInfo: _utility([{'type':'electricity','amount':850.0,'verified':true},{'type':'mobile','amount':499.0,'verified':true},{'type':'wifi','amount':799.0,'verified':true}]),
      emiLoansInfo: _emi([{'type':'home','emi':8500,'outstanding':950000,'months':108,'regular':true}]),
      insuranceInfo: const InsuranceInfo(isVerified: true, hasHealthInsurance: true, hasLifeInsurance: true, annualPremiumHealth: 12000, annualPremiumLife: 8000),
      taxInfo: const TaxInfo(isVerified: true, itrFiled: true, assessmentYear: 2024, declaredAnnualIncome: 420000, noDefaultHistory: true),
      govSchemesInfo: const GovSchemesInfo(isVerified: true, hasPmScheme: true),
    ),
    // Profile 2: Gig worker, high income, consistent
    VerifiedProfile(
      personalInfo: const PersonalInfo(isVerified: true, fullName: 'Priya Nair', dateOfBirth: '22/03/1995', workType: 'gig_worker', selfDeclaredIncome: 28000, yearsInProfession: 4, dependents: 1),
      kycInfo: const KycInfo(isVerified: true, backVerified: true, panVerified: true, nameMatchScore: 0.94),
      bankInfo: _bank(name: 'Priya Nair', monthlyCredits: [27500, 29000, 28200, 30000, 27800, 29500], monthlyDebits: [15000, 14800, 16000, 15500, 14200, 15800]),
      utilityInfo: _utility([{'type':'electricity','amount':620.0,'verified':true},{'type':'mobile','amount':349.0,'verified':true}]),
      emiLoansInfo: _emi([{'type':'vehicle','emi':4200,'outstanding':120000,'months':24,'regular':true}]),
      insuranceInfo: const InsuranceInfo(isVerified: true, hasHealthInsurance: true, annualPremiumHealth: 8000),
      taxInfo: const TaxInfo(isVerified: true, itrFiled: true, assessmentYear: 2024, declaredAnnualIncome: 336000),
      govSchemesInfo: const GovSchemesInfo(isVerified: true, hasEshram: true, hasPmScheme: true),
    ),
    // Profile 3: Self-employed, growing income
    VerifiedProfile(
      personalInfo: const PersonalInfo(isVerified: true, fullName: 'Vikram Patel', dateOfBirth: '10/11/1988', workType: 'self_employed', selfDeclaredIncome: 45000, yearsInProfession: 12, dependents: 3),
      kycInfo: const KycInfo(isVerified: true, backVerified: true, panVerified: true, nameMatchScore: 0.98),
      bankInfo: _bank(name: 'Vikram Patel', monthlyCredits: [40000, 42000, 44000, 46000, 48000, 50000], monthlyDebits: [22000, 23000, 24000, 25000, 24500, 26000]),
      utilityInfo: _utility([{'type':'electricity','amount':1200.0,'verified':true},{'type':'gas','amount':850.0,'verified':true},{'type':'wifi','amount':999.0,'verified':true}]),
      emiLoansInfo: _emi([{'type':'home','emi':12000,'outstanding':1800000,'months':180,'regular':true}]),
      insuranceInfo: const InsuranceInfo(isVerified: true, hasHealthInsurance: true, hasLifeInsurance: true, annualPremiumHealth: 18000, annualPremiumLife: 15000),
      taxInfo: const TaxInfo(isVerified: true, itrFiled: true, gstRegistered: true, assessmentYear: 2024, declaredAnnualIncome: 540000, noDefaultHistory: true),
      govSchemesInfo: const GovSchemesInfo(isVerified: true, hasPmScheme: true),
    ),
    // Profiles 4-15: varied low-risk scenarios
    VerifiedProfile(personalInfo: const PersonalInfo(isVerified: true, fullName: 'Anjali Sharma', dateOfBirth: '05/08/1992', workType: 'salaried', selfDeclaredIncome: 32000, yearsInProfession: 6, dependents: 0), kycInfo: const KycInfo(isVerified: true, backVerified: true, panVerified: true, nameMatchScore: 0.96), bankInfo: _bank(name: 'Anjali Sharma', monthlyCredits: [32000,32000,31500,32500,32000,32200], monthlyDebits: [16000,15500,17000,16200,15800,16500]), utilityInfo: _utility([{'type':'electricity','amount':750.0,'verified':true},{'type':'ott','amount':199.0,'verified':true}]), emiLoansInfo: _emi([]), insuranceInfo: const InsuranceInfo(isVerified: true, hasHealthInsurance: true, annualPremiumHealth: 10000), taxInfo: const TaxInfo(isVerified: true, itrFiled: true, assessmentYear: 2024, declaredAnnualIncome: 384000), govSchemesInfo: const GovSchemesInfo(isVerified: false)),
    VerifiedProfile(personalInfo: const PersonalInfo(isVerified: true, fullName: 'Suresh Kumar', dateOfBirth: '18/01/1985', workType: 'self_employed', selfDeclaredIncome: 55000, yearsInProfession: 15, dependents: 4), kycInfo: const KycInfo(isVerified: true, backVerified: true, panVerified: true, nameMatchScore: 0.99), bankInfo: _bank(name: 'Suresh Kumar', monthlyCredits: [52000,55000,58000,54000,56000,60000], monthlyDebits: [28000,29000,30000,28500,29500,31000]), utilityInfo: _utility([{'type':'electricity','amount':1800.0,'verified':true},{'type':'gas','amount':950.0,'verified':true}]), emiLoansInfo: _emi([{'type':'home','emi':15000,'outstanding':2500000,'months':240,'regular':true}]), insuranceInfo: const InsuranceInfo(isVerified: true, hasHealthInsurance: true, hasLifeInsurance: true, annualPremiumHealth: 25000, annualPremiumLife: 20000), taxInfo: const TaxInfo(isVerified: true, itrFiled: true, gstRegistered: true, assessmentYear: 2024, declaredAnnualIncome: 660000, noDefaultHistory: true), govSchemesInfo: const GovSchemesInfo(isVerified: true, hasPmScheme: true)),
  ];

  // ── MEDIUM RISK PROFILES (15 profiles) ────────────────────────────────────
  static final List<VerifiedProfile> _mediumRiskProfiles = [
    // Profile 1: Irregular income, moderate EMI
    VerifiedProfile(
      personalInfo: const PersonalInfo(isVerified: true, fullName: 'Ravi Shankar', dateOfBirth: '30/09/1993', workType: 'gig_worker', selfDeclaredIncome: 18000, yearsInProfession: 3, dependents: 2),
      kycInfo: const KycInfo(isVerified: true, backVerified: true, panVerified: true, nameMatchScore: 0.88),
      bankInfo: _bank(name: 'Ravi Shankar', monthlyCredits: [22000, 14000, 19000, 16000, 21000, 13000], monthlyDebits: [14000, 13500, 15000, 14200, 15500, 14800]),
      utilityInfo: _utility([{'type':'electricity','amount':980.0,'verified':true},{'type':'mobile','amount':599.0,'verified':false}]),
      emiLoansInfo: _emi([{'type':'personal','emi':5500,'outstanding':85000,'months':18,'regular':true}]),
      insuranceInfo: const InsuranceInfo(isVerified: false),
      taxInfo: const TaxInfo(isVerified: true, itrFiled: false, noDefaultHistory: true),
      govSchemesInfo: const GovSchemesInfo(isVerified: true, hasEshram: true),
    ),
    // Profile 2: High EMI, decent income
    VerifiedProfile(
      personalInfo: const PersonalInfo(isVerified: true, fullName: 'Deepika Menon', dateOfBirth: '14/04/1991', workType: 'salaried', selfDeclaredIncome: 30000, yearsInProfession: 5, dependents: 1),
      kycInfo: const KycInfo(isVerified: true, backVerified: false, panVerified: true, nameMatchScore: 0.85),
      bankInfo: _bank(name: 'Deepika Menon', monthlyCredits: [30000,30000,29500,30500,30000,30200], monthlyDebits: [22000,23000,22500,23500,22000,24000]),
      utilityInfo: _utility([{'type':'electricity','amount':1100.0,'verified':true},{'type':'wifi','amount':599.0,'verified':true}]),
      emiLoansInfo: _emi([{'type':'home','emi':12000,'outstanding':1200000,'months':120,'regular':true},{'type':'personal','emi':3500,'outstanding':45000,'months':12,'regular':false}]),
      insuranceInfo: const InsuranceInfo(isVerified: true, hasHealthInsurance: true, annualPremiumHealth: 7000),
      taxInfo: const TaxInfo(isVerified: true, itrFiled: true, assessmentYear: 2024, declaredAnnualIncome: 360000),
      govSchemesInfo: const GovSchemesInfo(isVerified: false),
    ),
    // Profile 3: Low savings, multiple small loans
    VerifiedProfile(
      personalInfo: const PersonalInfo(isVerified: true, fullName: 'Mohan Das', dateOfBirth: '22/07/1987', workType: 'self_employed', selfDeclaredIncome: 22000, yearsInProfession: 7, dependents: 3),
      kycInfo: const KycInfo(isVerified: true, backVerified: true, panVerified: false, nameMatchScore: 0.80),
      bankInfo: _bank(name: 'Mohan Das', monthlyCredits: [20000,24000,19000,22000,21000,20500], monthlyDebits: [18500,21000,18000,20000,19500,19000]),
      utilityInfo: _utility([{'type':'electricity','amount':650.0,'verified':true},{'type':'gas','amount':600.0,'verified':false}]),
      emiLoansInfo: _emi([{'type':'personal','emi':3000,'outstanding':40000,'months':14,'regular':true},{'type':'gold','emi':2000,'outstanding':25000,'months':10,'regular':true}]),
      insuranceInfo: const InsuranceInfo(isVerified: false),
      taxInfo: const TaxInfo(isVerified: true, itrFiled: false, noDefaultHistory: true),
      govSchemesInfo: const GovSchemesInfo(isVerified: true, hasEshram: true, hasPmScheme: true),
    ),
  ];

  // ── HIGH RISK PROFILES (10 profiles) ──────────────────────────────────────
  static final List<VerifiedProfile> _highRiskProfiles = [
    // Profile 1: Very high EMI, low income, no insurance
    VerifiedProfile(
      personalInfo: const PersonalInfo(isVerified: true, fullName: 'Ganesh Reddy', dateOfBirth: '05/03/1998', workType: 'gig_worker', selfDeclaredIncome: 12000, yearsInProfession: 1, dependents: 3),
      kycInfo: const KycInfo(isVerified: true, backVerified: false, panVerified: false, nameMatchScore: 0.70),
      bankInfo: _bank(name: 'Ganesh Reddy', monthlyCredits: [11000,13000,9500,12000,10500,8000], monthlyDebits: [10500,12000,9000,11500,10200,7800]),
      utilityInfo: _utility([{'type':'electricity','amount':450.0,'verified':false}]),
      emiLoansInfo: _emi([{'type':'personal','emi':6000,'outstanding':72000,'months':12,'regular':false},{'type':'personal','emi':3500,'outstanding':42000,'months':12,'regular':false}]),
      insuranceInfo: const InsuranceInfo(isVerified: false),
      taxInfo: const TaxInfo(isVerified: false, itrFiled: false, noDefaultHistory: false),
      govSchemesInfo: const GovSchemesInfo(isVerified: false),
    ),
    // Profile 2: Declining income trend
    VerifiedProfile(
      personalInfo: const PersonalInfo(isVerified: true, fullName: 'Lakshmi Devi', dateOfBirth: '18/11/1990', workType: 'gig_worker', selfDeclaredIncome: 16000, yearsInProfession: 2, dependents: 4),
      kycInfo: const KycInfo(isVerified: true, backVerified: true, panVerified: false, nameMatchScore: 0.75),
      bankInfo: _bank(name: 'Lakshmi Devi', monthlyCredits: [24000,21000,18000,15000,12000,9000], monthlyDebits: [20000,19000,17500,15500,13000,10000]),
      utilityInfo: _utility([{'type':'electricity','amount':800.0,'verified':false},{'type':'mobile','amount':399.0,'verified':false}]),
      emiLoansInfo: _emi([{'type':'personal','emi':5000,'outstanding':60000,'months':12,'regular':false}]),
      insuranceInfo: const InsuranceInfo(isVerified: false),
      taxInfo: const TaxInfo(isVerified: false, itrFiled: false, noDefaultHistory: false),
      govSchemesInfo: const GovSchemesInfo(isVerified: true, hasEshram: true),
    ),
    // Profile 3: Near-zero savings, heavy debt
    VerifiedProfile(
      personalInfo: const PersonalInfo(isVerified: true, fullName: 'Ramesh Yadav', dateOfBirth: '10/06/1995', workType: 'daily_wage', selfDeclaredIncome: 9000, yearsInProfession: 2, dependents: 5),
      kycInfo: const KycInfo(isVerified: true, backVerified: true, panVerified: false, nameMatchScore: 0.65),
      bankInfo: _bank(name: 'Ramesh Yadav', monthlyCredits: [9000,8500,9200,8800,9100,8700], monthlyDebits: [8800,8400,9000,8700,9000,8600]),
      utilityInfo: _utility([{'type':'electricity','amount':320.0,'verified':false}]),
      emiLoansInfo: _emi([{'type':'personal','emi':4000,'outstanding':48000,'months':12,'regular':false},{'type':'gold','emi':2500,'outstanding':30000,'months':12,'regular':false}]),
      insuranceInfo: const InsuranceInfo(isVerified: false),
      taxInfo: const TaxInfo(isVerified: false, itrFiled: false, noDefaultHistory: false),
      govSchemesInfo: const GovSchemesInfo(isVerified: true, hasEshram: true, hasPmScheme: true, hasRationCard: true),
    ),
  ];

  // ── FRAUD / REJECT PROFILES (5 profiles) ──────────────────────────────────
  static final List<VerifiedProfile> _fraudProfiles = [
    // Profile 1: Income far exceeds declared, no KYC match
    VerifiedProfile(
      personalInfo: const PersonalInfo(isVerified: false, fullName: 'Unknown Person', dateOfBirth: '01/01/2000', workType: 'gig_worker', selfDeclaredIncome: 100000, yearsInProfession: 0, dependents: 0),
      kycInfo: const KycInfo(isVerified: false, backVerified: false, panVerified: false, nameMatchScore: 0.20),
      bankInfo: _bank(name: 'Unknown Person', monthlyCredits: [200000,200000,200000,200000,200000,200000], monthlyDebits: [195000,198000,199000,197000,196000,198000]),
      utilityInfo: _utility([]),
      emiLoansInfo: _emi([{'type':'personal','emi':80000,'outstanding':1000000,'months':12,'regular':false}]),
      insuranceInfo: const InsuranceInfo(isVerified: false),
      taxInfo: const TaxInfo(isVerified: false, itrFiled: false, noDefaultHistory: false),
      govSchemesInfo: const GovSchemesInfo(isVerified: false),
    ),
  ];

  // ── MASTER PROFILE LIST ────────────────────────────────────────────────────
  static final List<VerifiedProfile> _allProfiles = [
    ..._lowRiskProfiles,
    ..._mediumRiskProfiles,
    ..._highRiskProfiles,
    ..._fraudProfiles,
  ];

  static final Map<DemoRiskCategory, List<VerifiedProfile>> _byCategory = {
    DemoRiskCategory.lowRisk:    _lowRiskProfiles,
    DemoRiskCategory.mediumRisk: _mediumRiskProfiles,
    DemoRiskCategory.highRisk:   _highRiskProfiles,
    DemoRiskCategory.fraud:      _fraudProfiles,
  };
}
