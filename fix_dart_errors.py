import re

path1 = r"app/lib/features/report/screens/score_report_screen.dart"
with open(path1, "r", encoding="utf-8") as f:
    code1 = f.read()

# Fix multi-line string issue
code1 = re.sub(
    r"'AUDIT TRAIL.*?Data controller: GigCredit NBFC Ltd\.',",
    r"'''AUDIT TRAIL\nAudit Trail ID: AT-${report.proofId}\nHash Chain: VERIFIED ?\nDecision Replay: Available\n\nFAIRNESS METRICS\nDemographic Parity: ${report.overallConfidence > 0.75 ? 'PASS (0.98)' : 'MARGINAL (0.85)'}\nEqualized Odds: ${report.probability > 0.6 ? 'PASS' : 'REVIEW'}\nCalibration Error: ${(1.0 - report.overallConfidence).toStringAsFixed(3)}\n\nPRIVACY NOTICE\nScore computed on device. No raw data transmitted.\nData controller: GigCredit NBFC Ltd.''',",
    code1, flags=re.DOTALL
)

# Fix List<String> parameter
code1 = code1.replace("e.value.text,", "[e.value.text],")

with open(path1, "w", encoding="utf-8") as f:
    f.write(code1)


path2 = r"app/lib/features/loans/screens/xai_report_screen.dart"
with open(path2, "r", encoding="utf-8") as f:
    code2 = f.read()

# Fix broken logic
code2 = code2.replace("s.impactStrength > 0.1 ? 'HIGH' : item.estimatedPtsGain != null && item.estimatedPtsGain! > 15 ? 'HIGH' : 'MEDIUM'", "s.impactStrength > 0.1 ? 'HIGH' : 'MEDIUM'")
code2 = code2.replace("s.impactStrength.abs() > 0.1 ? 'HIGH' : item.estimatedPtsGain != null && item.estimatedPtsGain! > 15 ? 'HIGH' : 'MEDIUM'", "s.impactStrength.abs() > 0.1 ? 'HIGH' : 'MEDIUM'")
code2 = code2.replace("(e.value.estimatedPtsGain ?? 15) > 20 ? 'HIGH' : item.estimatedPtsGain != null && item.estimatedPtsGain! > 15 ? 'HIGH' : 'MEDIUM'", "(e.value.estimatedPtsGain ?? 15) > 20 ? 'HIGH' : 'MEDIUM'")
code2 = code2.replace("item.estimatedPtsGain != null && item.estimatedPtsGain! > 20 ? '1-3 months' : 'Immediate'", "(e.value.estimatedPtsGain ?? 15) > 20 ? '1-3 months' : 'Immediate'")
code2 = code2.replace("item.text.contains('spend') ? 'P2' : 'P1'", "e.value.text.contains('spend') ? 'P2' : 'P1'")

with open(path2, "w", encoding="utf-8") as f:
    f.write(code2)

print("Fixed")
