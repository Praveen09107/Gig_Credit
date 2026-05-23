import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/enums/app_enums.dart';

class StepStatusNotifier extends StateNotifier<Map<int, StepStatus>> {
  StepStatusNotifier() : super({
    for (int i = 1; i <= 9; i++) i: StepStatus.notStarted,
  });

  void setStatus(int step, StepStatus status) {
    final updated = Map<int, StepStatus>.from(state);
    final wasAlreadyVerified = updated[step] == StepStatus.verified;
    updated[step] = status;

    // GAP 3 FIX: If a step is being re-verified (was already verified before),
    // invalidate all downstream steps so user must re-complete them.
    // This ensures cross-verification results stay consistent with the latest data.
    if (status == StepStatus.verified && wasAlreadyVerified) {
      for (int i = step + 1; i <= 9; i++) {
        if (updated[i] == StepStatus.verified) {
          updated[i] = StepStatus.notStarted;
        }
      }
    }

    state = updated;
  }

  bool isStepCompleted(int step) {
    return state[step] == StepStatus.verified;
  }

  /// Reset all steps so user can create a new report
  void reset() {
    state = {for (int i = 1; i <= 9; i++) i: StepStatus.notStarted};
  }

  /// GAP 3 FIX: Reset all downstream step statuses when user goes back
  /// and changes an earlier step. E.g. if Step 2 is re-submitted,
  /// Steps 3-9 are reset to notStarted so user must re-verify them.
  void resetStepsAfter(int step) {
    final updated = Map<int, StepStatus>.from(state);
    for (int i = step + 1; i <= 9; i++) {
      if (updated[i] == StepStatus.verified) {
        updated[i] = StepStatus.notStarted;
      }
    }
    state = updated;
  }
}

final stepStatusProvider = StateNotifierProvider<StepStatusNotifier, Map<int, StepStatus>>((ref) {
  return StepStatusNotifier();
});
