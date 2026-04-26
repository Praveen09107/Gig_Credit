import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoanApplication {
  final String refId;
  final String nbfcName;
  final int amount;
  final String tenure;
  final String purpose;
  final double rate;
  final DateTime appliedAt;
  final String status; // 'Processing' | 'Approved' | 'Disbursed'

  const LoanApplication({
    required this.refId,
    required this.nbfcName,
    required this.amount,
    required this.tenure,
    required this.purpose,
    required this.rate,
    required this.appliedAt,
    this.status = 'Processing',
  });
}

class LoanApplicationsNotifier extends StateNotifier<List<LoanApplication>> {
  LoanApplicationsNotifier() : super([]);

  void addApplication(LoanApplication app) {
    state = [app, ...state];
  }

  void clear() => state = [];
}

final loanApplicationsProvider =
    StateNotifierProvider<LoanApplicationsNotifier, List<LoanApplication>>(
  (ref) => LoanApplicationsNotifier(),
);
