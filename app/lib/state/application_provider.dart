import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/loan_application_model.dart';

class ApplicationNotifier extends StateNotifier<List<LoanApplicationModel>> {
  ApplicationNotifier() : super([]);

  void setApplications(List<LoanApplicationModel> apps) {
    state = apps;
  }

  void addApplication(LoanApplicationModel app) {
    state = [app, ...state];
  }

  void updateApplication(LoanApplicationModel updatedApp) {
    state = [
      for (final app in state)
        if (app.id == updatedApp.id) updatedApp else app
    ];
  }
}

final applicationProvider = StateNotifierProvider<ApplicationNotifier, List<LoanApplicationModel>>((ref) {
  return ApplicationNotifier();
});
