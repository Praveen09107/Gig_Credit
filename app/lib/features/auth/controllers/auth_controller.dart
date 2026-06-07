import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../state/auth_provider.dart';
import '../../../../state/user_provider.dart';
import '../../../../state/api_service_provider.dart';
import '../../../../models/user_model.dart';
import '../../../../services/session_service.dart';

class AuthController extends StateNotifier<bool> {
  final Ref ref;

  AuthController(this.ref) : super(false); // state = isLoading

  Future<String?> sendOtp(String mobile,
      {bool isSignup = false, String? name}) async {
    state = true;
    try {
      final api = ref.read(apiServiceProvider);
      final response =
          await api.sendOtp(mobile, isSignup: isSignup, name: name);
      state = false;
      if (response['status'] == 'success') {
        return response['otp'] ?? 'TWILIO_SUCCESS';
      }
      return response['otp'];
    } catch (e) {
      state = false;
      // Return the error message string so the screen can show a specific toast
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      ref.read(authProvider.notifier).setError(errorMsg);
      return 'ERROR:$errorMsg';
    }
  }

  Future<bool> verifyOtp(String mobile, String otp) async {
    state = true;
    try {
      final api = ref.read(apiServiceProvider);
      final response = await api.verifyOtp(mobile, otp);

      if (response['status'] == 'success') {
        final token = response['token'] as String? ?? '';
        final userData = response['user'] as Map<String, dynamic>? ?? {};

        final user = UserModel(
          id: 'USR_$mobile',
          name: userData['name'] as String? ?? '',
          mobile: mobile,
          isVerified: false,
        );

        // ── Persist session to secure storage ──────────────────
        await SessionService.saveSession(token: token, user: user);

        ref.read(userProvider.notifier).setUser(user);
        ref.read(authProvider.notifier).setAuthenticated(
              userId: user.id,
              token: token,
            );

        state = false;
        return true;
      }
      state = false;
      ref
          .read(authProvider.notifier)
          .setError('Unexpected response from server');
      return false;
    } catch (e) {
      state = false;
      ref
          .read(authProvider.notifier)
          .setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  /// Real logout: clears secure storage + in-memory state
  Future<void> logout() async {
    await SessionService.clearSession();
    ref.read(authProvider.notifier).logout();
    ref.read(userProvider.notifier).clearUser();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, bool>((ref) {
  return AuthController(ref);
});
