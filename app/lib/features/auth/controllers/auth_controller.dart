import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../state/auth_provider.dart';
import '../../../../state/user_provider.dart';
import '../../../../state/api_service_provider.dart';
import '../../../../models/user_model.dart';

class AuthController extends StateNotifier<bool> {
  final Ref ref;

  AuthController(this.ref) : super(false); // state = isLoading

  Future<String?> sendOtp(String mobile, {bool isSignup = false, String? name}) async {
    state = true;
    try {
      final api = ref.read(apiServiceProvider);
      final response = await api.sendOtp(mobile, isSignup: isSignup, name: name);
      state = false;
      return response['otp'];
    } catch (e) {
      state = false;
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      ref.read(authProvider.notifier).setError(errorMsg);
      return null;
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
      ref.read(authProvider.notifier).setError(e.toString().replaceAll('Exception: ', ''));
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
