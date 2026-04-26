import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/credit_balance_model.dart';

class CreditNotifier extends StateNotifier<CreditBalanceModel> {
  CreditNotifier() : super(const CreditBalanceModel());

  void setBalance(CreditBalanceModel balance) {
    state = balance;
  }

  void consumeCredit() {
    if (state.freeRemaining > 0) {
      state = state.copyWith(freeRemaining: state.freeRemaining - 1);
    } else if (state.paidBalance >= 10) {
      state = state.copyWith(paidBalance: state.paidBalance - 10);
    }
  }

  void addPaidCredits(int credits) {
    state = state.copyWith(paidBalance: state.paidBalance + credits);
  }
}

final creditProvider = StateNotifierProvider<CreditNotifier, CreditBalanceModel>((ref) {
  return CreditNotifier();
});
