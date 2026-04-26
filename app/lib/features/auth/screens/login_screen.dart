import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/inputs/phone_input_field.dart';
import '../../../shared/widgets/buttons/primary_button.dart';
import '../../../shared/widgets/status/inline_message_banner.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_mode_switcher.dart';
import '../../../app/app_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _mobileController = TextEditingController();
  bool _isMobileValid = false;
  String? _errorMsg;

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  void _validate(String value) {
    setState(() {
      _isMobileValid = value.length == 10;
      _errorMsg = null;
    });
  }

  Future<void> _handleLogin() async {
    final mobile = _mobileController.text;
    final success = await ref.read(authControllerProvider.notifier).sendOtp(mobile);
    
    if (success && mounted) {
      context.push('${AppRoutes.otp}?mobile=$mobile&isSignup=false');
    } else {
      setState(() {
        _errorMsg = 'Failed to send OTP. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),
                      // Header
                      Text('Welcome back', style: AppTypography.displayMedium),
                      const SizedBox(height: 8),
                      Text(
                        'Enter your mobile number to access your credit profile',
                        style: AppTypography.bodyMedium,
                      ),
                      const SizedBox(height: 40),

                      // Form
                      if (_errorMsg != null) ...[
                        InlineMessageBanner(message: _errorMsg!),
                        const SizedBox(height: 16),
                      ],
                      
                      PhoneInputField(
                        controller: _mobileController,
                        onChanged: _validate,
                      ),
                      const SizedBox(height: 32),
                      
                      PrimaryButton(
                        label: 'Send OTP',
                        isLoading: isLoading,
                        isDisabled: !_isMobileValid,
                        onPressed: _handleLogin,
                      ),
                      
                      const Spacer(),
                      const AuthModeSwitcher(isLogin: true),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
