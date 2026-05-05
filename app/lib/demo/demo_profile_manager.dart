import '../models/verified_profile/verified_profile.dart';
import 'demo_profile_service.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// DemoProfileManager — Singleton that selects ONE profile on first trigger
/// and returns the SAME profile for every subsequent step.
///
/// RULES:
///   1. Profile is selected ONCE (first double-tap in any step)
///   2. ALL subsequent steps reuse the SAME profile
///   3. Profile data populates UI controllers → user clicks Submit → normal flow
///   4. NO pipeline bypass — data goes through VerifiedProfile → FeatureEng → ML
/// ─────────────────────────────────────────────────────────────────────────────
class DemoProfileManager {
  // ── Singleton ──────────────────────────────────────────────────────────────
  static final DemoProfileManager _instance = DemoProfileManager._internal();
  factory DemoProfileManager() => _instance;
  DemoProfileManager._internal();

  VerifiedProfile? _activeProfile;
  int _currentIndex = 0;

  /// Whether a demo profile is currently loaded
  bool get isActive => _activeProfile != null;

  /// Get the active profile (loads one if not yet selected)
  VerifiedProfile get profile {
    _activeProfile ??= _selectProfile();
    return _activeProfile!;
  }

  /// Select the next profile in round-robin fashion for variety during demos
  VerifiedProfile _selectProfile() {
    final allProfiles = DemoProfileService.allProfiles;
    final selected = allProfiles[_currentIndex % allProfiles.length];
    _currentIndex++;
    return selected;
  }

  /// Reset — clears the active profile so a new one is selected on next trigger
  void reset() {
    _activeProfile = null;
  }
}
