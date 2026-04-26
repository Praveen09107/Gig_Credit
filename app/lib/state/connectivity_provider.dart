import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/enums/app_enums.dart';

class ConnectivityNotifier extends StateNotifier<ConnectivityStatus> {
  ConnectivityNotifier() : super(ConnectivityStatus.online);

  void setStatus(ConnectivityStatus status) {
    state = status;
  }
}

final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, ConnectivityStatus>((ref) {
  return ConnectivityNotifier();
});
