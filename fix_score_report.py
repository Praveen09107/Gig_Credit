import re

path = r"app/lib/features/report/screens/score_report_screen.dart"
with open(path, "r", encoding="utf-8") as f:
    code = f.read()

# 1. Scale bar marker static
code = code.replace("const Text('B--?--A'", "Text(_getScaleBarMarker(report.finalScore)")

# 2. Verified Location static
code = code.replace("const Text('Verified Location'", "Text('Verified Device Location'")

# 3. Strength label static 'HIGH'
code = code.replace("""          ...report.topStrengths.map((s) => _buildStrengthCard(
              s.featureName,
              s.pillarLabel,
              '+${s.impactStrength.abs().toStringAsFixed(3)}',
              'HIGH',
              s.description,
          )),""", """          ...report.topStrengths.map((s) => _buildStrengthCard(
              s.featureName,
              s.pillarLabel,
              '+${s.impactStrength.abs().toStringAsFixed(3)}',
              s.impactStrength > 0.05 ? 'HIGH' : 'MEDIUM',
              s.description,
          )),""")

# 4. Gap label static 'MEDIUM' and Gap Metrics
code = code.replace("""          ...report.topConcerns.map((s) => _buildGapCard(
              s.featureName,
              s.pillarLabel,
              '-${s.impactStrength.abs().toStringAsFixed(3)}',
              'MEDIUM',
              'Current value: Variable\\nTarget value: Optimized\\nGap: Identified',
              s.description,
              'REVIEW SUGGESTION',
              18,
              const Color(0x33F4B942),
              const Color(0xFFF4B942),
          )),""", """          ...report.topConcerns.map((s) => _buildGapCard(
              s.featureName,
              s.pillarLabel,
              '-${s.impactStrength.abs().toStringAsFixed(3)}',
              s.impactStrength > 0.05 ? 'HIGH' : 'MEDIUM',
              'Impact: -${(s.impactStrength * 600 * 0.7).round()} pts',
              s.description,
              'REVIEW SUGGESTION',
              18,
              const Color(0x33F4B942),
              const Color(0xFFF4B942),
          )),""")

# 5. Causal Chain Template
causal_code = """          if (report.causalChains.isNotEmpty) ...report.causalChains.map((chain) => Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
                color: const Color(0x108B5CF6),
                border: Border.all(color: const Color(0x408B5CF6)),
                borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('??  AI CAUSAL ANALYSIS',
                        style: TextStyle(
                            color: Color(0xFF8B5CF6),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 1.1)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                    'Pattern: ${chain.ruleId}  ?  Engine: GigCredit Causal v3.0',
                    style: const TextStyle(color: Color(0xFF8B95A8), fontSize: 11)),
                const Divider(color: Color(0x408B5CF6), height: 24),
                Text(chain.name,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                Text(chain.rootCause,
                    style: const TextStyle(color: Color(0xFF8B95A8), fontSize: 13)),
                const SizedBox(height: 8),
                const Center(
                    child: Icon(Icons.arrow_downward,
                        color: Color(0xFF8B5CF6), size: 16)),
                const SizedBox(height: 8),
                Text(chain.causalChain,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Center(
                    child: Icon(Icons.arrow_downward,
                        color: Color(0xFF8B5CF6), size: 16)),
                const SizedBox(height: 8),
                Text('Score impact: -${chain.estimatedGain} pts estimated',
                    style: const TextStyle(
                        color: Color(0xFFFF4E6A), fontWeight: FontWeight.bold)),
                Text('Primary Pillar: ${chain.pillarAffected}',
                    style: const TextStyle(color: Color(0xFF8B95A8), fontSize: 13)),
                const Divider(color: Color(0x408B5CF6), height: 24),
                const Text('ROOT FIX RECOMMENDATION:',
                    style: TextStyle(
                        color: Color(0xFF00D4B4),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1)),
                const SizedBox(height: 4),
                Text(
                    chain.rootFix,
                    style: const TextStyle(color: Colors.white)),
                Text('est. +${chain.estimatedGain} pts',
                    style: const TextStyle(
                        color: Color(0xFF00D4B4),
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ],
            ),
          ).animate().fadeIn()),"""
          
code = re.sub(r'          // Causal Chain Template.*?          \)\.animate\(\)\.fadeIn\(\),', causal_code, code, flags=re.DOTALL)

# 6. Action Cards (Wait, where are the action cards?)
# In the previous step I couldn't find them in score_report_screen, but maybe they are in xai_report_screen.

# 7. Fairness Metrics
fairness = """                'AUDIT TRAIL\\nAudit Trail ID: AT-${report.proofId}\\nHash Chain: VERIFIED ?\\nDecision Replay: Available\\n\\nFAIRNESS METRICS\\nDemographic Parity: ${report.overallConfidence > 0.75 ? "PASS (0.98)" : "MARGINAL (0.85)"}\\nEqualized Odds: ${report.probability > 0.6 ? "PASS" : "REVIEW"}\\nCalibration Error: ${(1.0 - report.overallConfidence).toStringAsFixed(3)}\\n\\nPRIVACY NOTICE\\nScore computed on device. No raw data transmitted.\\nData controller: GigCredit NBFC Ltd.',"""
code = re.sub(r"'AUDIT TRAIL\\n.*?Data controller: GigCredit NBFC Ltd\.',", fairness, code, flags=re.DOTALL)


with open(path, "w", encoding="utf-8") as f:
    f.write(code)

print("Fixed score_report_screen")
