class TrajectoryPath {
  final int projectedScore;
  final String projectedGrade;
  final String timeframe;
  final List<String> appliedActions;

  const TrajectoryPath({
    required this.projectedScore,
    required this.projectedGrade,
    required this.timeframe,
    required this.appliedActions,
  });
}

class TrajectoryResult {
  final TrajectoryPath sevenDay;
  final TrajectoryPath oneToThreeMonths;
  final TrajectoryPath fullPotential;

  const TrajectoryResult({
    required this.sevenDay,
    required this.oneToThreeMonths,
    required this.fullPotential,
  });
}
