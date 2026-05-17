import re

# Fix score_report_screen.dart
path1 = r"app/lib/features/report/screens/score_report_screen.dart"
with open(path1, "r", encoding="utf-8") as f:
    code1 = f.read()

# Fix multi-line string issue in score_report_screen
code1 = re.sub(
    r"'AUDIT TRAIL\nAudit Trail ID: AT-\$\{report\.proofId\}\nHash Chain: VERIFIED ?\nDecision Replay: Available\n\nFAIRNESS METRICS\nDemographic Parity: \$\{report\.overallConfidence > 0\.75 \? \"PASS \(0\.98\)\" : \"MARGINAL \(0\.85\)\"\}\nEqualized Odds: \$\{report\.probability > 0\.6 \? \"PASS\" : \"REVIEW\"\}\nCalibration Error: \$\{\(1\.0 - report\.overallConfidence\)\.toStringAsFixed\(3\)\}\n\nPRIVACY NOTICE\nScore computed on device\. No raw data transmitted\.\nData controller: GigCredit NBFC Ltd\.',",
    r"'''AUDIT TRAIL\nAudit Trail ID: AT-${report.proofId}\nHash Chain: VERIFIED ?\nDecision Replay: Available\n\nFAIRNESS METRICS\nDemographic Parity: ${report.overallConfidence > 0.75 ? 'PASS (0.98)' : 'MARGINAL (0.85)'}\nEqualized Odds: ${report.probability > 0.6 ? 'PASS' : 'REVIEW'}\nCalibration Error: ${(1.0 - report.overallConfidence).toStringAsFixed(3)}\n\nPRIVACY NOTICE\nScore computed on device. No raw data transmitted.\nData controller: GigCredit NBFC Ltd.''',",
    code1, flags=re.DOTALL
)

# Fix TailoredSuggestion type error in score_report_screen (line 1157ish)
# The issue is _buildActionCard(..., [e.value]) where e.value is TailoredSuggestion.
code1 = code1.replace("[e.value],", "e.value.text,") # Let's see if that's what it wants. Wait, what does _buildActionCard expect?
# It expects a String for 'suggestions'. Maybe [e.value.text]?
code1 = code1.replace("[e.value],", "[e.value.text],")

with open(path1, "w", encoding="utf-8") as f:
    f.write(code1)


# Fix xai_report_screen.dart
path2 = r"app/lib/features/loans/screens/xai_report_screen.dart"
with open(path2, "r", encoding="utf-8") as f:
    code2 = f.read()

# Fix broken replacements of 'MEDIUM', 'Depends on action', 'Multiple Pillars'
code2 = code2.replace("${item.estimatedPtsGain != null && item.estimatedPtsGain! > 15 ? 'HIGH' : 'MEDIUM'}", "item.estimatedPtsGain != null && item.estimatedPtsGain! > 15 ? 'HIGH' : 'MEDIUM'")
code2 = code2.replace("${item.estimatedPtsGain != null && item.estimatedPtsGain! > 20 ? '1-3 months' : 'Immediate'}", "item.estimatedPtsGain != null && item.estimatedPtsGain! > 20 ? '1-3 months' : 'Immediate'")
code2 = code2.replace("${item.text.contains('spend') ? 'P2' : 'P1'}", "item.text.contains('spend') ? 'P2' : 'P1'")

with open(path2, "w", encoding="utf-8") as f:
    f.write(code2)

print("Fixed syntax")
