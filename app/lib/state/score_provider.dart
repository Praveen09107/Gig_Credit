import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/score_report_model.dart';
import '../core/enums/app_enums.dart';

class ScoreSessionState {
  final ScoreGenerationStatus status;
  final ScoreReportModel? reportData;
  final String? errorMessage;

  const ScoreSessionState({
    this.status = ScoreGenerationStatus.idle,
    this.reportData,
    this.errorMessage,
  });

  ScoreSessionState copyWith({
    ScoreGenerationStatus? status,
    ScoreReportModel? reportData,
    String? errorMessage,
  }) => ScoreSessionState(
    status: status ?? this.status,
    reportData: reportData ?? this.reportData,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}

class ScoreNotifier extends StateNotifier<ScoreSessionState> {
  ScoreNotifier() : super(const ScoreSessionState());

  void setGenerating() {
    state = state.copyWith(status: ScoreGenerationStatus.generating);
  }

  void setSuccess(ScoreReportModel report) {
    state = state.copyWith(
      status: ScoreGenerationStatus.success,
      reportData: report,
      errorMessage: null,
    );
  }

  void setError(String message) {
    state = state.copyWith(
      status: ScoreGenerationStatus.error,
      errorMessage: message,
    );
  }

  void reset() {
    state = const ScoreSessionState();
  }
}

final scoreProvider = StateNotifierProvider<ScoreNotifier, ScoreSessionState>((ref) {
  return ScoreNotifier();
});
