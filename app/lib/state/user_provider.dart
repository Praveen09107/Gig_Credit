import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../core/enums/app_enums.dart';
import 'auth_provider.dart';

class UserNotifier extends StateNotifier<UserModel?> {
  UserNotifier() : super(null);

  void setUser(UserModel user) {
    state = user;
  }

  void updateName(String name) {
    if (state != null) {
      state = UserModel(
        id: state!.id,
        mobile: state!.mobile,
        name: name,
        isVerified: state!.isVerified,
      );
    }
  }

  void setVerified(bool isVerified) {
    if (state != null) {
      state = UserModel(
        id: state!.id,
        mobile: state!.mobile,
        name: state!.name,
        isVerified: isVerified,
      );
    }
  }

  void clearUser() {
    state = null;
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserModel?>((ref) {
  final auth = ref.watch(authProvider);
  final notifier = UserNotifier();
  
  if (auth.status == AuthStatus.unauthenticated) {
    // We don't call clearUser here because we might just be listening,
    // but the actual logout process should clear the user.
  }
  
  return notifier;
});
