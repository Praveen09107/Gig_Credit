import 'package:flutter_test/flutter_test.dart';

import 'package:gigcredit/scoring/features/feature_engineer.dart';
import 'package:gigcredit/scoring/engine/scoring_engine.dart';
import 'package:gigcredit/scoring/engine/confidence_engine.dart';
import 'package:gigcredit/scoring/engine/meta_learner.dart';
import 'package:gigcredit/scoring/score_pipeline.dart';
import 'package:gigcredit/scoring/models/scoring_constants.dart';

import 'package:gigcredit/models/verified_profile/verified_profile.dart';
import 'package:gigcredit/models/verified_profile/personal_info.dart';
import 'package:gigcredit/models/verified_profile/kyc_info.dart';
import 'package:gigcredit/models/verified_profile/bank_info.dart';
import 'package:gigcredit/models/verified_profile/work_info.dart';
import 'package:gigcredit/models/verified_profile/utility_info.dart';
import 'package:gigcredit/models/verified_profile/gov_schemes_info.dart';
import 'package:gigcredit/models/verified_profile/insurance_info.dart';
import 'package:gigcredit/models/verified_profile/tax_info.dart';
import 'package:gigcredit/models/verified_profile/emi_loans_info.dart';

void main() {
  // ── Canonical Demo Profile ──────────────────────────────────
  late VerifiedProfile demoProfile;

  setUp(() {
    demoProfile = VerifiedProfile(
      personalInfo: PersonalInfo(
        fullName: 'Ravi Kumar',
        dateOfBirth: '1997-06-12',
        mobileNumber: '9876543210',
        currentAddress: '123 MG Road, Bengaluru',
        permanentAddress: '456 Station Road, Chennai',
        selfDeclaredIncome: 25000,
        dependents: 1,
        yearsInProfession: 4,
        workType: 'platform_worker',
        vehicleOwnership: true,
        stateOfResidence: 'Karnataka',
        isVerified: true,
      ),
      kycInfo: KycInfo(isVerified: true),
      bankInfo: BankInfo(isVerified: true),
      workInfo: WorkInfo(isVerified: true),
      utilityInfo: UtilityInfo(isVerified: true),
      govSchemesInfo: GovSchemesInfo(isVerified: true),
      insuranceInfo: InsuranceInfo(isVerified: true),
      taxInfo: TaxInfo(isVerified: true),
      emiLoansInfo: EmiLoansInfo(isVerified: true),
    );
  });

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  group('FeatureEngineer', () {
    test('produces exactly 95 features', () {
      final features = FeatureEngineer.extract(demoProfile);
      expect(features.length, 95);
    });

    test('all features are in [0.0, 1.0]', () {
      final features = FeatureEngineer.extract(demoProfile);
      for (int i = 0; i < features.length; i++) {
        expect(features[i], greaterThanOrEqualTo(0.0), reason: 'f[$i] < 0');
        expect(features[i], lessThanOrEqualTo(1.0), reason: 'f[$i] > 1');
      }
    });

    test('verified profile has identity features > 0', () {
      final features = FeatureEngineer.extract(demoProfile);
      // f49 = aadhaar_verified, f50 = pan_verified
      expect(features[49], 1.0);
      expect(features[50], 1.0);
    });

    test('income normalized correctly for ₹25,000', () {
      final features = FeatureEngineer.extract(demoProfile);
      // f0 = income_to_anchor_ratio = 25000/50000 = 0.5
      expect(features[0], 0.5);
    });

    test('work type encoded correctly for platform_worker', () {
      final features = FeatureEngineer.extract(demoProfile);
      // f55 = work_type_encoded = 0.7 for platform_worker
      expect(features[55], 0.7);
    });

    test('unverified profile uses defaults', () {
      final emptyProfile = VerifiedProfile(
        personalInfo: PersonalInfo(fullName: '', dateOfBirth: '', mobileNumber: '', currentAddress: '', permanentAddress: '', selfDeclaredIncome: 0, dependents: 0, yearsInProfession: 0, workType: '', vehicleOwnership: false, stateOfResidence: '', isVerified: false),
        kycInfo: KycInfo(isVerified: false),
        bankInfo: BankInfo(isVerified: false),
        workInfo: WorkInfo(isVerified: false),
        utilityInfo: UtilityInfo(isVerified: false),
        govSchemesInfo: GovSchemesInfo(isVerified: false),
        insuranceInfo: InsuranceInfo(isVerified: false),
        taxInfo: TaxInfo(isVerified: false),
        emiLoansInfo: EmiLoansInfo(isVerified: false),
      );
      final features = FeatureEngineer.extract(emptyProfile);
      expect(features.length, 95);
      // f49 = aadhaar_verified should be 0 when not verified
      expect(features[49], 0.0);
    });
  });

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  group('ScoringEngine', () {
    test('produces exactly 7 pillar scores', () {
      final features = FeatureEngineer.extract(demoProfile);
      final engine = ScoringEngine();
      final pillars = engine.scorePillars(features);
      expect(pillars.length, 7);
      expect(pillars.keys.toSet(), {'p1', 'p2', 'p3', 'p4', 'p5', 'p6', 'p7'});
    });

    test('all pillar scores are in [0.0, 1.0]', () {
      final features = FeatureEngineer.extract(demoProfile);
      final engine = ScoringEngine();
      final pillars = engine.scorePillars(features);
      for (final entry in pillars.entries) {
        expect(entry.value, greaterThanOrEqualTo(0.0), reason: '${entry.key} < 0');
        expect(entry.value, lessThanOrEqualTo(1.0), reason: '${entry.key} > 1');
      }
    });

    test('pillar labels map has 7 entries', () {
      expect(ScoringEngine.pillarLabels.length, 7);
    });
  });

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  group('ConfidenceEngine', () {
    test('confidence is in [0.0, 1.0]', () {
      final features = FeatureEngineer.extract(demoProfile);
      final confidence = ConfidenceEngine.computeConfidence(features);
      expect(confidence, greaterThanOrEqualTo(0.0));
      expect(confidence, lessThanOrEqualTo(1.0));
    });

    test('fully verified profile has high confidence', () {
      final features = FeatureEngineer.extract(demoProfile);
      final confidence = ConfidenceEngine.computeConfidence(features);
      expect(confidence, greaterThan(0.5));
    });

    test('per-pillar confidence returns 7 pillars', () {
      final features = FeatureEngineer.extract(demoProfile);
      final conf = ConfidenceEngine.computePillarConfidence(features);
      expect(conf.length, 7);
    });

    test('adjustScore shrinks toward 0.5 with low confidence', () {
      final adjusted = ConfidenceEngine.adjustScore(0.8, 0.0);
      expect(adjusted, 0.5); // 0.8 * 0.0 + 0.5 * 1.0 = 0.5
    });

    test('adjustScore preserves score with full confidence', () {
      final adjusted = ConfidenceEngine.adjustScore(0.8, 1.0);
      expect(adjusted, 0.8);
    });
  });

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  group('MetaLearner', () {
    test('buildMetaInput produces 19 elements', () {
      final pillars = {'p1': 0.6, 'p2': 0.7, 'p3': 0.5, 'p4': 0.6, 'p5': 0.8, 'p6': 0.4, 'p7': 0.5};
      final input = MetaLearner.buildMetaInput(pillars, 'platform_worker');
      expect(input.length, 19);
    });

    test('work-type one-hot encoding is correct', () {
      final pillars = {'p1': 0.5, 'p2': 0.5, 'p3': 0.5, 'p4': 0.5, 'p5': 0.5, 'p6': 0.5, 'p7': 0.5};

      final pw = MetaLearner.buildMetaInput(pillars, 'platform_worker');
      expect(pw[7], 1.0); // w_platform
      expect(pw[8], 0.0); // w_vendor

      final vendor = MetaLearner.buildMetaInput(pillars, 'vendor');
      expect(vendor[7], 0.0);
      expect(vendor[8], 1.0);
    });

    test('predict returns score in [300, 900]', () {
      final pillars = {'p1': 0.6, 'p2': 0.7, 'p3': 0.5, 'p4': 0.6, 'p5': 0.8, 'p6': 0.4, 'p7': 0.5};
      final score = MetaLearner.predict(pillars, 'platform_worker');
      expect(score, greaterThanOrEqualTo(300));
      expect(score, lessThanOrEqualTo(900));
    });

    test('getGrade returns valid grade', () {
      expect(MetaLearner.getGrade(800), 'A+');
      expect(MetaLearner.getGrade(550), 'C');
    });

    test('getRiskLevel returns valid risk', () {
      expect(MetaLearner.getRiskLevel(750), 'Low');
      expect(MetaLearner.getRiskLevel(500), 'High');
    });
  });

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  group('ScorePipeline (E2E)', () {
    test('full pipeline produces valid ScoreReportModel', () {
      final report = ScorePipeline.run(demoProfile);
      expect(report.finalScore, greaterThanOrEqualTo(300));
      expect(report.finalScore, lessThanOrEqualTo(900));
      expect(report.grade, isNotEmpty);
      expect(report.riskBand, isNotEmpty);
      expect(report.pillars.length, 7);
      expect(report.topStrengths.length, 3);
      expect(report.topConcerns.length, 3);
    });

    test('pillar display models have correct codes', () {
      final report = ScorePipeline.run(demoProfile);
      final codes = report.pillars.map((p) => p.code).toSet();
      expect(codes, {'p1', 'p2', 'p3', 'p4', 'p5', 'p6', 'p7'});
    });

    test('each pillar score <= maxScore', () {
      final report = ScorePipeline.run(demoProfile);
      for (final pillar in report.pillars) {
        expect(pillar.score, lessThanOrEqualTo(pillar.maxScore),
            reason: '${pillar.code}: ${pillar.score} > ${pillar.maxScore}');
      }
    });

    test('proofId starts with GC-', () {
      final report = ScorePipeline.run(demoProfile);
      expect(report.proofId, startsWith('GC-'));
    });

    test('confidence is between 0 and 1', () {
      final report = ScorePipeline.run(demoProfile);
      expect(report.overallConfidence, greaterThanOrEqualTo(0.0));
      expect(report.overallConfidence, lessThanOrEqualTo(1.0));
    });
  });

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  group('Scoring Constants', () {
    test('probabilityToScore maps correctly', () {
      expect(probabilityToScore(0.0), 300);
      expect(probabilityToScore(1.0), 900);
      expect(probabilityToScore(0.5), 600);
    });

    test('scoreToGrade covers full range', () {
      expect(scoreToGrade(850), 'A+');
      expect(scoreToGrade(300), 'D');
    });
  });
}
