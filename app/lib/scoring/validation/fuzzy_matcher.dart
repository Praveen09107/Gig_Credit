import 'dart:math';

/// ─────────────────────────────────────────────────────────────────────────────
/// FuzzyMatcher — On-device fuzzy string matching for identity verification
///
/// Implements Jaro-Winkler similarity (preferred for names) and Levenshtein
/// distance. Used across all 9 steps for cross-document name verification.
///
/// Thresholds (from spec):
///   ≥ 0.85 (85%) → PASS
///   0.60–0.84    → SOFT FLAG (warning, non-blocking)
///   < 0.60       → HARD FAIL (blocking)
/// ─────────────────────────────────────────────────────────────────────────────
class FuzzyMatcher {
  /// Jaro-Winkler similarity score between two strings (0.0–1.0).
  /// Best suited for short strings like person names.
  static double jaroWinkler(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final a = s1.toUpperCase().trim();
    final b = s2.toUpperCase().trim();

    if (a == b) return 1.0;

    final jaro = _jaroSimilarity(a, b);

    // Winkler modification: boost for common prefix (up to 4 chars)
    int prefixLen = 0;
    for (int i = 0; i < min(4, min(a.length, b.length)); i++) {
      if (a[i] == b[i]) {
        prefixLen++;
      } else {
        break;
      }
    }

    const double p = 0.1; // Winkler scaling factor
    return jaro + (prefixLen * p * (1.0 - jaro));
  }

  /// Core Jaro similarity computation.
  static double _jaroSimilarity(String a, String b) {
    final int maxDist = (max(a.length, b.length) / 2).floor() - 1;
    if (maxDist < 0) return 0.0;

    final matchedA = List<bool>.filled(a.length, false);
    final matchedB = List<bool>.filled(b.length, false);

    int matches = 0;
    int transpositions = 0;

    // Find matching characters
    for (int i = 0; i < a.length; i++) {
      final start = max(0, i - maxDist);
      final end = min(b.length - 1, i + maxDist);
      for (int j = start; j <= end; j++) {
        if (matchedB[j] || a[i] != b[j]) continue;
        matchedA[i] = true;
        matchedB[j] = true;
        matches++;
        break;
      }
    }

    if (matches == 0) return 0.0;

    // Count transpositions
    int k = 0;
    for (int i = 0; i < a.length; i++) {
      if (!matchedA[i]) continue;
      while (!matchedB[k]) k++;
      if (a[i] != b[k]) transpositions++;
      k++;
    }

    return (matches / a.length +
            matches / b.length +
            (matches - transpositions / 2) / matches) /
        3.0;
  }

  /// Levenshtein edit distance between two strings.
  static int levenshteinDistance(String s1, String s2) {
    final a = s1.toUpperCase().trim();
    final b = s2.toUpperCase().trim();

    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    List<int> prev = List.generate(b.length + 1, (i) => i);
    List<int> curr = List.filled(b.length + 1, 0);

    for (int i = 1; i <= a.length; i++) {
      curr[0] = i;
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        curr[j] = min(min(curr[j - 1] + 1, prev[j] + 1), prev[j - 1] + cost);
      }
      final temp = prev;
      prev = curr;
      curr = temp;
    }
    return prev[b.length];
  }

  /// Normalized Levenshtein similarity (0.0–1.0).
  static double levenshteinSimilarity(String s1, String s2) {
    final maxLen = max(s1.length, s2.length);
    if (maxLen == 0) return 1.0;
    return 1.0 - (levenshteinDistance(s1, s2) / maxLen);
  }

  /// Combined name similarity using best of Jaro-Winkler and Levenshtein.
  /// Handles common Indian name variations (initials, middle names, etc.)
  static double nameSimilarity(String name1, String name2) {
    if (name1.isEmpty || name2.isEmpty) return 0.0;

    // Normalize: uppercase, remove extra spaces, remove titles
    final n1 = _normalizeName(name1);
    final n2 = _normalizeName(name2);

    if (n1 == n2) return 1.0;

    // Direct Jaro-Winkler
    final jwScore = jaroWinkler(n1, n2);

    // Token-sorted comparison (handles word order differences)
    final tokenScore = _tokenSortedSimilarity(n1, n2);

    // Token-set comparison (handles missing/extra middle names)
    final setScore = _tokenSetSimilarity(n1, n2);

    // Return best score
    return [jwScore, tokenScore, setScore].reduce(max);
  }

  /// Normalize Indian names: remove titles, extra whitespace, common suffixes
  static String _normalizeName(String name) {
    String n = name.toUpperCase().trim();

    // Remove common Indian titles/prefixes
    final titles = ['MR', 'MRS', 'MS', 'DR', 'SHRI', 'SMT', 'KUMARI', 'THIRU', 'SELVI'];
    for (final t in titles) {
      n = n.replaceAll(RegExp('^$t\\.?\\s+', caseSensitive: false), '');
      n = n.replaceAll(RegExp('\\s+$t\\.?\$', caseSensitive: false), '');
    }

    // Remove dots after initials (K. → K)
    n = n.replaceAll('.', ' ');

    // Collapse multiple spaces
    n = n.replaceAll(RegExp(r'\s+'), ' ').trim();

    return n;
  }

  /// Token-sorted: sort words alphabetically then compare
  static double _tokenSortedSimilarity(String a, String b) {
    final tokensA = a.split(' ')..sort();
    final tokensB = b.split(' ')..sort();
    return jaroWinkler(tokensA.join(' '), tokensB.join(' '));
  }

  /// Token-set: compare intersection and remainder tokens
  static double _tokenSetSimilarity(String a, String b) {
    final setA = a.split(' ').toSet();
    final setB = b.split(' ').toSet();
    final intersection = setA.intersection(setB);

    if (intersection.isEmpty) return 0.0;

    final remainderA = setA.difference(intersection);
    final remainderB = setB.difference(intersection);

    final sorted = intersection.toList()..sort();
    final combined1 = [...sorted, ...remainderA.toList()..sort()].join(' ');
    final combined2 = [...sorted, ...remainderB.toList()..sort()].join(' ');

    final t0 = sorted.join(' ');
    final s1 = jaroWinkler(t0, combined1);
    final s2 = jaroWinkler(t0, combined2);
    final s3 = jaroWinkler(combined1, combined2);

    return [s1, s2, s3].reduce(max);
  }

  /// Check if name match passes the spec threshold.
  /// Returns a result with score, pass/fail, and severity.
  static NameMatchResult matchNames(String name1, String name2) {
    final score = nameSimilarity(name1, name2);

    if (score >= 0.85) {
      return NameMatchResult(
        score: score,
        passed: true,
        severity: MatchSeverity.pass,
        message: 'Names match (${(score * 100).toStringAsFixed(1)}%)',
      );
    } else if (score >= 0.60) {
      return NameMatchResult(
        score: score,
        passed: true, // soft flag = non-blocking
        severity: MatchSeverity.softFlag,
        message: 'Partial name match (${(score * 100).toStringAsFixed(1)}%) — review recommended',
      );
    } else {
      return NameMatchResult(
        score: score,
        passed: false,
        severity: MatchSeverity.hardFail,
        message: 'Name mismatch (${(score * 100).toStringAsFixed(1)}%) — identity verification failed',
      );
    }
  }
}

/// Severity levels for match results
enum MatchSeverity { pass, softFlag, hardFail }

/// Result of a name matching operation
class NameMatchResult {
  final double score;
  final bool passed;
  final MatchSeverity severity;
  final String message;

  const NameMatchResult({
    required this.score,
    required this.passed,
    required this.severity,
    required this.message,
  });
}
