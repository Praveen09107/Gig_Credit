import 'package:flutter_test/flutter_test.dart';
import 'package:gigcredit/scoring/validation/cross_step_validator.dart';

void main() {
  group('CrossStepValidator', () {
    // ── Name Mismatch Tests ──
    test('No issues when Aadhaar and PAN names match', () {
      final issues = CrossStepValidator.validate({
        'aadhaar_front': {'name': 'Ravi Kumar', 'dob': '15/06/1995'},
        'pan': {'name': 'RAVI KUMAR', 'dob': '15/06/1995', 'id_number': 'BXYPK4532N'},
      });
      final nameIssues = issues.where((i) => i.code == 'NAME_MISMATCH_AADHAAR_PAN');
      expect(nameIssues, isEmpty, reason: 'Same name should not trigger mismatch');
    });

    test('WARNING when Aadhaar and PAN names differ', () {
      final issues = CrossStepValidator.validate({
        'aadhaar_front': {'name': 'Ravi Kumar', 'dob': '15/06/1995'},
        'pan': {'name': 'JOHN DOE', 'dob': '15/06/1995', 'id_number': 'BXYPK4532N'},
      });
      final nameIssues = issues.where((i) => i.code == 'NAME_MISMATCH_AADHAAR_PAN').toList();
      expect(nameIssues.length, equals(1));
      expect(nameIssues.first.severity, equals(IssueSeverity.warning));
      expect(nameIssues.first.field1, equals('Ravi Kumar'));
      expect(nameIssues.first.field2, equals('JOHN DOE'));
    });

    test('No name issue when only one document is present', () {
      final issues = CrossStepValidator.validate({
        'aadhaar_front': {'name': 'Ravi Kumar'},
      });
      expect(issues.where((i) => i.code == 'NAME_MISMATCH_AADHAAR_PAN'), isEmpty);
    });

    // ── DOB Mismatch Tests ──
    test('No DOB issue when dates match', () {
      final issues = CrossStepValidator.validate({
        'aadhaar_front': {'name': 'Ravi Kumar', 'dob': '15/06/1995'},
        'pan': {'name': 'RAVI KUMAR', 'dob': '15/06/1995'},
      });
      expect(issues.where((i) => i.code == 'DOB_MISMATCH_AADHAAR_PAN'), isEmpty);
    });

    test('WARNING when DOBs differ', () {
      final issues = CrossStepValidator.validate({
        'aadhaar_front': {'name': 'Ravi Kumar', 'dob': '15/06/1995'},
        'pan': {'name': 'RAVI KUMAR', 'dob': '20/03/1990'},
      });
      final dobIssues = issues.where((i) => i.code == 'DOB_MISMATCH_AADHAAR_PAN').toList();
      expect(dobIssues.length, equals(1));
      expect(dobIssues.first.severity, equals(IssueSeverity.warning));
    });

    // ── Vehicle Mismatch Tests ──
    test('No vehicle issue when RC and insurance match', () {
      final issues = CrossStepValidator.validate({
        'work_rc': {'vehicle_number': 'TN 09 AB 1234'},
        'insurance_vehicle': {'vehicle_number': 'TN09AB1234'},
      });
      expect(issues.where((i) => i.code == 'VEHICLE_MISMATCH_RC_INSURANCE'), isEmpty);
    });

    test('WARNING when RC and insurance vehicles differ', () {
      final issues = CrossStepValidator.validate({
        'work_rc': {'vehicle_number': 'TN 09 AB 1234'},
        'insurance_vehicle': {'vehicle_number': 'KA 01 CD 5678'},
      });
      final vIssues = issues.where((i) => i.code == 'VEHICLE_MISMATCH_RC_INSURANCE').toList();
      expect(vIssues.length, equals(1));
    });

    // ── PAN Consistency Tests ──
    test('ERROR when KYC PAN and ITR PAN differ', () {
      final issues = CrossStepValidator.validate({
        'pan': {'id_number': 'BXYPK4532N'},
        'tax_itr': {'pan': 'ZZZZZ9999Z'},
      });
      final panIssues = issues.where((i) => i.code == 'PAN_MISMATCH_KYC_ITR').toList();
      expect(panIssues.length, equals(1));
      expect(panIssues.first.severity, equals(IssueSeverity.error));
    });

    test('No PAN issue when KYC and ITR PAN match', () {
      final issues = CrossStepValidator.validate({
        'pan': {'id_number': 'BXYPK4532N'},
        'tax_itr': {'pan': 'BXYPK4532N'},
      });
      expect(issues.where((i) => i.code == 'PAN_MISMATCH_KYC_ITR'), isEmpty);
    });

    // ── Blocking Errors ──
    test('hasBlockingErrors returns true when ERROR issues exist', () {
      final issues = CrossStepValidator.validate({
        'pan': {'id_number': 'BXYPK4532N'},
        'tax_itr': {'pan': 'ZZZZZ9999Z'},
      });
      expect(CrossStepValidator.hasBlockingErrors(issues), isTrue);
    });

    test('hasBlockingErrors returns false when only warnings', () {
      final issues = CrossStepValidator.validate({
        'aadhaar_front': {'name': 'Ravi Kumar', 'dob': '15/06/1995'},
        'pan': {'name': 'JOHN DOE', 'dob': '15/06/1995'},
      });
      expect(CrossStepValidator.hasBlockingErrors(issues), isFalse);
    });

    // ── Empty Input ──
    test('No issues with empty OCR results', () {
      final issues = CrossStepValidator.validate({});
      expect(issues, isEmpty);
    });

    // ── getDisplayableIssues ──
    test('getDisplayableIssues filters out INFO severity', () {
      final issues = [
        const ValidationIssue(
          code: 'TEST_INFO', title: 'Info', description: 'test',
          severity: IssueSeverity.info, steps: [1], field1: '', field2: '',
        ),
        const ValidationIssue(
          code: 'TEST_WARN', title: 'Warn', description: 'test',
          severity: IssueSeverity.warning, steps: [2], field1: 'a', field2: 'b',
        ),
      ];
      final displayable = CrossStepValidator.getDisplayableIssues(issues);
      expect(displayable.length, equals(1));
      expect(displayable.first.code, equals('TEST_WARN'));
    });

    // ── Full demo data: no mismatches (canonical inputs) ──
    test('Canonical demo data produces zero issues', () {
      final issues = CrossStepValidator.validate({
        'aadhaar_front': {'name': 'Ravi Kumar', 'dob': '15/06/1995', 'id_number': '8765 4321 9012'},
        'pan': {'name': 'RAVI KUMAR', 'dob': '15/06/1995', 'id_number': 'BXYPK4532N'},
        'work_rc': {'vehicle_number': 'TN 09 AB 1234'},
        'insurance_vehicle': {'vehicle_number': 'TN 09 AB 1234'},
        'tax_itr': {'pan': 'BXYPK4532N'},
      });
      expect(issues, isEmpty, reason: 'Canonical demo data should have zero cross-step issues');
    });
  });
}
