import '../../models/trajectory_result.dart';
import '../../models/actionable_item.dart';
// To get score_to_grade mapping if needed, or we implement a simple one

class Layer4Trajectory {
  static TrajectoryResult simulate(int currentScore, List<ActionableItem> actionableList) {
    // Top 3 immediate
    var immediateActions = actionableList
        .where((a) => a.tier == ActionabilityTier.immediate)
        .take(3)
        .toList();

    int score7Day = currentScore;
    List<String> actions7Day = [];
    for (var a in immediateActions) {
      score7Day += a.expectedGainPts;
      actions7Day.add(a.actionText);
    }
    score7Day = score7Day.clamp(300, 900);

    // Immediate + top 2 behavioural
    var behaviouralActions = actionableList
        .where((a) => a.tier == ActionabilityTier.behavioural)
        .take(2)
        .toList();

    int score1to3Months = score7Day;
    List<String> actions1to3Months = List.from(actions7Day);
    for (var a in behaviouralActions) {
      score1to3Months += a.expectedGainPts;
      actions1to3Months.add(a.actionText);
    }
    score1to3Months = score1to3Months.clamp(300, 900);

    // Full potential (up to top 5 actions total)
    int scoreFull = currentScore;
    List<String> actionsFull = [];
    for (var a in actionableList.take(5)) {
      scoreFull += a.expectedGainPts;
      actionsFull.add(a.actionText);
    }
    scoreFull = scoreFull.clamp(300, 900);

    return TrajectoryResult(
      sevenDay: TrajectoryPath(
        projectedScore: score7Day,
        projectedGrade: _scoreToGrade(score7Day),
        timeframe: '7 Days',
        appliedActions: actions7Day,
      ),
      oneToThreeMonths: TrajectoryPath(
        projectedScore: score1to3Months,
        projectedGrade: _scoreToGrade(score1to3Months),
        timeframe: '1-3 Months',
        appliedActions: actions1to3Months,
      ),
      fullPotential: TrajectoryPath(
        projectedScore: scoreFull,
        projectedGrade: _scoreToGrade(scoreFull),
        timeframe: 'Full Potential',
        appliedActions: actionsFull,
      ),
    );
  }

  static String _scoreToGrade(int score) {
    if (score >= 800) return "A+";
    if (score >= 750) return "A";
    if (score >= 700) return "B+";
    if (score >= 650) return "B";
    if (score >= 600) return "C+";
    if (score >= 550) return "C";
    return "D";
  }
}
