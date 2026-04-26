import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/enums/app_enums.dart';

class StepStatusNotifier extends StateNotifier<Map<int, StepStatus>> {
  StepStatusNotifier() : super({
    for (int i = 1; i <= 9; i++) i: StepStatus.notStarted,
  });

  void setStatus(int step, StepStatus status) {
    final updated = Map<int, StepStatus>.from(state);
    updated[step] = status;
    state = updated;
  }

  bool isStepCompleted(int step) {
    return state[step] == StepStatus.verified;
  }

  /// Reset all steps so user can create a new report
  void reset() {
    state = {for (int i = 1; i <= 9; i++) i: StepStatus.notStarted};
  }
}

final stepStatusProvider = StateNotifierProvider<StepStatusNotifier, Map<int, StepStatus>>((ref) {
  return StepStatusNotifier();
});
