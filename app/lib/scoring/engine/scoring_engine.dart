// Real m2cgen-exported models from Dev A's ML pipeline
import '../models/p1_scorer.dart' as p1;
import '../models/p2_scorer.dart' as p2;
import '../models/p3_scorer.dart' as p3;
import '../models/p4_scorer.dart' as p4;
import '../models/p6_scorer.dart' as p6;
import '../models/scorecard_p5.dart';
import '../models/scorecard_p7.dart';
import '../models/scorecard_p8.dart';

class ScoringEngine {
  /// Sklearn-compatible isotonic interpolation.
  /// Matches sklearn.isotonic.IsotonicRegression.predict() exactly.
  /// [xKnots] and [yKnots] are from calibration_knots.json per pillar.
  static double isotonicInterpolate(double x, List<double> xKnots, List<double> yKnots) {
    // Below lower bound → return leftmost y (sklearn clips, not extrapolates)
    if (x <= xKnots.first) return yKnots.first;

    // Above upper bound → return rightmost y (sklearn clips, not extrapolates)
    if (x >= xKnots.last) return yKnots.last;

    // Binary search for the interval [xKnots[i], xKnots[i+1]] containing x
    int lo = 0, hi = xKnots.length - 2;
    while (lo < hi) {
      int mid = (lo + hi) ~/ 2;
      if (xKnots[mid + 1] < x) { lo = mid + 1; } else { hi = mid; }
    }

    // Linear interpolation within interval (piecewise linear = sklearn default)
    double t = (x - xKnots[lo]) / (xKnots[lo + 1] - xKnots[lo]);
    return yKnots[lo] + t * (yKnots[lo + 1] - yKnots[lo]);
  }

  static Map<String, double> scorePillars(List<double> f) {
    Map<String, double> scores = {};

    // Real m2cgen models: P1/P2/P3/P4/P6 use exported score() functions
    // P5/P7/P8 use hand-written scorecard classes
    scores['P1'] = p1.score([...f.sublist(0, 13), f[95], f[96], f[97], f[98]]);
    scores['P2'] = p2.score([...f.sublist(13, 28), f[105], f[106], f[107], f[108]]);
    scores['P3'] = p3.score([...f.sublist(28, 37), f[95], f[96], f[97], f[98]]);
    scores['P4'] = p4.score([...f.sublist(37, 49), f[99], f[100], f[101], f[102]]);
    scores['P5'] = P5Scorecard.score(f.sublist(49, 67));
    scores['P6'] = p6.score([...f.sublist(67, 78), f[102], f[103], f[104]]);
    scores['P7'] = P7Scorecard.score(f.sublist(78, 88));
    scores['P8'] = P8Scorecard.score(f.sublist(88, 95));

    // Clamp all to [0, 1]
    scores.forEach((key, value) {
      scores[key] = value.clamp(0.0, 1.0);
    });

    return scores;
  }

  static Map<String, double> calibrateScores(Map<String, double> rawScores, Map<String, dynamic> calibrationKnotsJson) {
    Map<String, double> calibrated = {};
    
    // Only P1, P2, P3, P4, P6 get calibrated
    rawScores.forEach((pillar, score) {
      if (['P1', 'P2', 'P3', 'P4', 'P6'].contains(pillar)) {
        if (calibrationKnotsJson.containsKey(pillar)) {
          var knotData = calibrationKnotsJson[pillar];
          List<double> xKnots = List<double>.from(knotData['x'].map((x) => (x as num).toDouble()));
          List<double> yKnots = List<double>.from(knotData['y'].map((y) => (y as num).toDouble()));
          calibrated[pillar] = isotonicInterpolate(score, xKnots, yKnots).clamp(0.0, 1.0);
        } else {
          calibrated[pillar] = score; // Fallback
        }
      } else {
        calibrated[pillar] = score; // Pass through P5, P7, P8
      }
    });

    return calibrated;
  }
}
