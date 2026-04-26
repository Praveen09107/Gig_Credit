import 'package:flutter/material.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import 'package:go_router/go_router.dart';
import '../../../app/app_router.dart';

class AuthModeSwitcher extends StatelessWidget {
  final bool isLogin;

  const AuthModeSwitcher({super.key, required this.isLogin});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isLogin ? "Don't have an account? " : "Already have an account? ",
          style: AppTypography.bodyMedium,
        ),
        GestureDetector(
          onTap: () {
            if (isLogin) {
              context.go(AppRoutes.signup);
            } else {
              context.go(AppRoutes.login);
            }
          },
          child: Text(
            isLogin ? "Sign Up" : "Log In",
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.accentLight,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
