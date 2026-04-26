import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'secure_storage.dart';
import '../../state/verified_profile_provider.dart';
import '../../state/step_status_provider.dart';
import '../../state/auth_provider.dart';
import '../../state/credit_provider.dart';
import '../../models/verified_profile/verified_profile.dart';
import '../../models/credit_balance_model.dart';
import '../../core/enums/app_enums.dart';

/// P4-01: Session Manager
/// Persists and restores the full application state across app restarts.
/// Supports 24-hour session expiry and explicit reset.
class SessionManager {
  final Ref _ref;
  SessionManager(this._ref);

  /// Save all current state to encrypted storage
  Future<void> saveSession() async {
    // Save verified profile
    final profile = _ref.read(verifiedProfileProvider);
    await SecureStorage.saveProfile(profile.toJson());

    // Save step progress
    final steps = _ref.read(stepStatusProvider);
    final stepStrings = steps.map((k, v) => MapEntry(k, v.name));
    await SecureStorage.saveStepProgress(stepStrings);

    // Save auth session
    final auth = _ref.read(authProvider);
    if (auth.isAuthenticated && auth.userId != null && auth.token != null) {
      await SecureStorage.saveAuthSession(userId: auth.userId!, token: auth.token!);
    }

    // Save credits
    final credits = _ref.read(creditProvider);
    await SecureStorage.saveCredits(credits.toJson());
  }

  /// Restore all state from encrypted storage
  /// Returns true if session was restored successfully
  Future<bool> restoreSession() async {
    try {
      // Restore auth
      final authData = await SecureStorage.loadAuthSession();
      if (authData != null) {
        _ref.read(authProvider.notifier).setAuthenticated(
          userId: authData['userId'] as String,
          token: authData['token'] as String,
        );
      }

      // Restore profile
      final profileData = await SecureStorage.loadProfile();
      if (profileData != null) {
        final profile = VerifiedProfile.fromJson(profileData);
        _ref.read(verifiedProfileProvider.notifier).updateProfile(profile);
      }

      // Restore step progress
      final stepData = await SecureStorage.loadStepProgress();
      if (stepData != null) {
        for (final entry in stepData.entries) {
          final status = StepStatus.values.firstWhere(
            (s) => s.name == entry.value,
            orElse: () => StepStatus.notStarted,
          );
          _ref.read(stepStatusProvider.notifier).setStatus(entry.key, status);
        }
      }

      // Restore credits
      final creditData = await SecureStorage.loadCredits();
      if (creditData != null) {
        _ref.read(creditProvider.notifier).setBalance(CreditBalanceModel.fromJson(creditData));
      }

      return authData != null;
    } catch (_) {
      return false;
    }
  }

  /// Clear all persisted state (logout)
  Future<void> clearSession() async {
    await SecureStorage.clearAll();
  }
}

final sessionManagerProvider = Provider<SessionManager>((ref) {
  return SessionManager(ref);
});
