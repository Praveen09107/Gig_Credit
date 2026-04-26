import 'personal_info.dart';
import 'kyc_info.dart';
import 'bank_info.dart';
import 'utility_info.dart';
import 'work_info.dart';
import 'gov_schemes_info.dart';
import 'insurance_info.dart';
import 'tax_info.dart';
import 'emi_loans_info.dart';

class VerifiedProfile {
  PersonalInfo personalInfo;
  KycInfo kycInfo;
  BankInfo bankInfo;
  UtilityInfo utilityInfo;
  WorkInfo workInfo;
  GovSchemesInfo govSchemesInfo;
  InsuranceInfo insuranceInfo;
  TaxInfo taxInfo;
  EmiLoansInfo emiLoansInfo;

  VerifiedProfile({
    this.personalInfo = const PersonalInfo(),
    this.kycInfo = const KycInfo(),
    this.bankInfo = const BankInfo(),
    this.utilityInfo = const UtilityInfo(),
    this.workInfo = const WorkInfo(),
    this.govSchemesInfo = const GovSchemesInfo(),
    this.insuranceInfo = const InsuranceInfo(),
    this.taxInfo = const TaxInfo(),
    this.emiLoansInfo = const EmiLoansInfo(),
  });

  factory VerifiedProfile.fromJson(Map<String, dynamic> json) => VerifiedProfile(
    personalInfo: json['personalInfo'] != null
        ? PersonalInfo.fromJson(json['personalInfo'] as Map<String, dynamic>)
        : const PersonalInfo(),
    kycInfo: json['kycInfo'] != null
        ? KycInfo.fromJson(json['kycInfo'] as Map<String, dynamic>)
        : const KycInfo(),
    bankInfo: json['bankInfo'] != null
        ? BankInfo.fromJson(json['bankInfo'] as Map<String, dynamic>)
        : const BankInfo(),
    utilityInfo: json['utilityInfo'] != null
        ? UtilityInfo.fromJson(json['utilityInfo'] as Map<String, dynamic>)
        : const UtilityInfo(),
    workInfo: json['workInfo'] != null
        ? WorkInfo.fromJson(json['workInfo'] as Map<String, dynamic>)
        : const WorkInfo(),
    govSchemesInfo: json['govSchemesInfo'] != null
        ? GovSchemesInfo.fromJson(json['govSchemesInfo'] as Map<String, dynamic>)
        : const GovSchemesInfo(),
    insuranceInfo: json['insuranceInfo'] != null
        ? InsuranceInfo.fromJson(json['insuranceInfo'] as Map<String, dynamic>)
        : const InsuranceInfo(),
    taxInfo: json['taxInfo'] != null
        ? TaxInfo.fromJson(json['taxInfo'] as Map<String, dynamic>)
        : const TaxInfo(),
    emiLoansInfo: json['emiLoansInfo'] != null
        ? EmiLoansInfo.fromJson(json['emiLoansInfo'] as Map<String, dynamic>)
        : const EmiLoansInfo(),
  );

  Map<String, dynamic> toJson() => {
    'personalInfo': personalInfo.toJson(),
    'kycInfo': kycInfo.toJson(),
    'bankInfo': bankInfo.toJson(),
    'utilityInfo': utilityInfo.toJson(),
    'workInfo': workInfo.toJson(),
    'govSchemesInfo': govSchemesInfo.toJson(),
    'insuranceInfo': insuranceInfo.toJson(),
    'taxInfo': taxInfo.toJson(),
    'emiLoansInfo': emiLoansInfo.toJson(),
  };
}
