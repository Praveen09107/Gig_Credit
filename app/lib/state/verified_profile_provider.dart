import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/verified_profile/verified_profile.dart';
import '../models/verified_profile/personal_info.dart';
import '../models/verified_profile/kyc_info.dart';
import '../models/verified_profile/bank_info.dart';
import '../models/verified_profile/utility_info.dart';
import '../models/verified_profile/work_info.dart';
import '../models/verified_profile/gov_schemes_info.dart';
import '../models/verified_profile/insurance_info.dart';
import '../models/verified_profile/tax_info.dart';
import '../models/verified_profile/emi_loans_info.dart';
import '../demo/demo_profile_manager.dart';

class VerifiedProfileNotifier extends StateNotifier<VerifiedProfile> {
  VerifiedProfileNotifier() : super(VerifiedProfile());

  void updateProfile(VerifiedProfile profile) {
    state = profile;
  }

  void updateStep1(PersonalInfo info) {
    state = VerifiedProfile(
      personalInfo: info,
      kycInfo: state.kycInfo,
      bankInfo: state.bankInfo,
      utilityInfo: state.utilityInfo,
      workInfo: state.workInfo,
      govSchemesInfo: state.govSchemesInfo,
      insuranceInfo: state.insuranceInfo,
      taxInfo: state.taxInfo,
      emiLoansInfo: state.emiLoansInfo,
    );
  }

  void updateStep2(KycInfo info) {
    state = VerifiedProfile(
      personalInfo: state.personalInfo,
      kycInfo: info,
      bankInfo: state.bankInfo,
      utilityInfo: state.utilityInfo,
      workInfo: state.workInfo,
      govSchemesInfo: state.govSchemesInfo,
      insuranceInfo: state.insuranceInfo,
      taxInfo: state.taxInfo,
      emiLoansInfo: state.emiLoansInfo,
    );
  }

  void updateStep3(BankInfo info) {
    state = VerifiedProfile(
      personalInfo: state.personalInfo,
      kycInfo: state.kycInfo,
      bankInfo: info,
      utilityInfo: state.utilityInfo,
      workInfo: state.workInfo,
      govSchemesInfo: state.govSchemesInfo,
      insuranceInfo: state.insuranceInfo,
      taxInfo: state.taxInfo,
      emiLoansInfo: state.emiLoansInfo,
    );
  }

  void updateStep4(UtilityInfo info) {
    state = VerifiedProfile(
      personalInfo: state.personalInfo,
      kycInfo: state.kycInfo,
      bankInfo: state.bankInfo,
      utilityInfo: info,
      workInfo: state.workInfo,
      govSchemesInfo: state.govSchemesInfo,
      insuranceInfo: state.insuranceInfo,
      taxInfo: state.taxInfo,
      emiLoansInfo: state.emiLoansInfo,
    );
  }

  void updateStep5(WorkInfo info) {
    state = VerifiedProfile(
      personalInfo: state.personalInfo,
      kycInfo: state.kycInfo,
      bankInfo: state.bankInfo,
      utilityInfo: state.utilityInfo,
      workInfo: info,
      govSchemesInfo: state.govSchemesInfo,
      insuranceInfo: state.insuranceInfo,
      taxInfo: state.taxInfo,
      emiLoansInfo: state.emiLoansInfo,
    );
  }

  void updateStep6(GovSchemesInfo info) {
    state = VerifiedProfile(
      personalInfo: state.personalInfo,
      kycInfo: state.kycInfo,
      bankInfo: state.bankInfo,
      utilityInfo: state.utilityInfo,
      workInfo: state.workInfo,
      govSchemesInfo: info,
      insuranceInfo: state.insuranceInfo,
      taxInfo: state.taxInfo,
      emiLoansInfo: state.emiLoansInfo,
    );
  }

  void updateStep7(InsuranceInfo info) {
    state = VerifiedProfile(
      personalInfo: state.personalInfo,
      kycInfo: state.kycInfo,
      bankInfo: state.bankInfo,
      utilityInfo: state.utilityInfo,
      workInfo: state.workInfo,
      govSchemesInfo: state.govSchemesInfo,
      insuranceInfo: info,
      taxInfo: state.taxInfo,
      emiLoansInfo: state.emiLoansInfo,
    );
  }

  void updateStep8(TaxInfo info) {
    state = VerifiedProfile(
      personalInfo: state.personalInfo,
      kycInfo: state.kycInfo,
      bankInfo: state.bankInfo,
      utilityInfo: state.utilityInfo,
      workInfo: state.workInfo,
      govSchemesInfo: state.govSchemesInfo,
      insuranceInfo: state.insuranceInfo,
      taxInfo: info,
      emiLoansInfo: state.emiLoansInfo,
    );
  }

  void updateStep9(EmiLoansInfo info) {
    state = VerifiedProfile(
      personalInfo: state.personalInfo,
      kycInfo: state.kycInfo,
      bankInfo: state.bankInfo,
      utilityInfo: state.utilityInfo,
      workInfo: state.workInfo,
      govSchemesInfo: state.govSchemesInfo,
      insuranceInfo: state.insuranceInfo,
      taxInfo: state.taxInfo,
      emiLoansInfo: info,
    );
  }

  /// Reset all data for a new report session
  void reset() {
    state = VerifiedProfile();
    DemoProfileManager().reset();
  }
}

final verifiedProfileProvider = StateNotifierProvider<VerifiedProfileNotifier, VerifiedProfile>((ref) {
  return VerifiedProfileNotifier();
});
