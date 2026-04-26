import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/loan_offer_model.dart';
import '../core/enums/app_enums.dart';

class LoanState {
  final LoanEligibilityStatus status;
  final List<LoanOfferModel> offers;

  const LoanState({
    this.status = LoanEligibilityStatus.loading,
    this.offers = const [],
  });

  LoanState copyWith({
    LoanEligibilityStatus? status,
    List<LoanOfferModel>? offers,
  }) => LoanState(
    status: status ?? this.status,
    offers: offers ?? this.offers,
  );
}

class LoanNotifier extends StateNotifier<LoanState> {
  LoanNotifier() : super(const LoanState());

  void setOffers(List<LoanOfferModel> offers) {
    state = state.copyWith(
      status: offers.isEmpty ? LoanEligibilityStatus.noOffers : LoanEligibilityStatus.eligible,
      offers: offers,
    );
  }

  void setNoScore() {
    state = state.copyWith(status: LoanEligibilityStatus.noScore, offers: []);
  }

  void setLoading() {
    state = state.copyWith(status: LoanEligibilityStatus.loading);
  }
}

final loanProvider = StateNotifierProvider<LoanNotifier, LoanState>((ref) {
  return LoanNotifier();
});
