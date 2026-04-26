import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../state/auth_provider.dart';
import '../../../../state/user_provider.dart';
import '../../../../state/api_service_provider.dart';
import '../../../../models/user_model.dart';

class AuthController extends StateNotifier<bool> {
  final Ref ref;

  AuthController(this.ref) : super(false); // state = isLoading

  Future<bool> sendOtp(String mobile, {bool isSignup = false}) async {
    state = true;
    try {
      final api = ref.read(apiServiceProvider);
      await api.sendOtp(mobile, isSignup: isSignup);
      state = false;
      return true;
    } catch (e) {
      state = false;
      ref.read(authProvider.notifier).setError(e.toString());
      return false;
    }
  }

  Future<bool> verifyOtp(String mobile, String otp) async {
    state = true;
    try {
      final api = ref.read(apiServiceProvider);
      final response = await api.verifyOtp(mobile, otp);
      
      if (response['status'] == 'success') {
        final token = response['token'];
        final userData = response['user'];
        
        final user = UserModel(
          id: 'USR_${DateTime.now().millisecondsSinceEpoch}',
          name: userData['name'],
          mobile: mobile,
          isVerified: false,
        );

        ref.read(userProvider.notifier).setUser(user);
        ref.read(authProvider.notifier).setAuthenticated(userId: user.id, token: token);
        
        state = false;
        return true;
      }
      return false;
    } catch (e) {
      state = false;
      ref.read(authProvider.notifier).setError('Invalid OTP or connection error');
      return false;
    }
  }

  void logout() {
    ref.read(authProvider.notifier).logout();
    ref.read(userProvider.notifier).clearUser();
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, bool>((ref) {
  return AuthController(ref);
});
