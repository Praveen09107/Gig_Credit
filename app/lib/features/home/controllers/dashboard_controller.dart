import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardState {
  final bool isLoading;
  
  const DashboardState({this.isLoading = false});
}

class DashboardController extends StateNotifier<DashboardState> {
  final Ref ref;

  DashboardController(this.ref) : super(const DashboardState());

  Future<void> refreshAll() async {
    state = const DashboardState(isLoading: true);
    // Simulate network delay for fetching dashboard data
    await Future.delayed(const Duration(seconds: 1));
    state = const DashboardState(isLoading: false);
  }
}

final dashboardControllerProvider = StateNotifierProvider<DashboardController, DashboardState>((ref) {
  return DashboardController(ref);
});
