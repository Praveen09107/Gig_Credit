import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/inputs/phone_input_field.dart';
import '../../../shared/widgets/inputs/app_text_field.dart';
import '../../../shared/widgets/buttons/primary_button.dart';
import '../../../shared/widgets/status/inline_message_banner.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_mode_switcher.dart';
import '../../../app/app_router.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  
  bool _isValid = false;
  String? _errorMsg;

  @override
  void dispose() {
    _mobileController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _validate() {
    setState(() {
      _isValid = _mobileController.text.length == 10 && _nameController.text.isNotEmpty;
      _errorMsg = null;
    });
  }

  Future<void> _handleSignup() async {
    final mobile = _mobileController.text;
    final success = await ref.read(authControllerProvider.notifier).sendOtp(mobile, isSignup: true);
    
    if (success && mounted) {
      context.push('${AppRoutes.otp}?mobile=$mobile&isSignup=true');
    } else {
      setState(() {
        _errorMsg = 'Registration failed. Number might be in use.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              
              Text('Create Account', style: AppTypography.displayMedium),
              const SizedBox(height: 8),
              Text(
                'Unlock tailored credit products',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 40),

              if (_errorMsg != null) ...[
                InlineMessageBanner(message: _errorMsg!),
                const SizedBox(height: 16),
              ],

              AppTextField(
                label: 'Full Name (as per ID)',
                hint: 'e.g. Praveen K',
                controller: _nameController,
                onChanged: (_) => _validate(),
              ),
              const SizedBox(height: 24),
              
              PhoneInputField(
                controller: _mobileController,
                onChanged: (_) => _validate(),
              ),
              const SizedBox(height: 32),
              
              PrimaryButton(
                label: 'Continue',
                isLoading: isLoading,
                isDisabled: !_isValid,
                onPressed: _handleSignup,
              ),
              
              const SizedBox(height: 48),
              const AuthModeSwitcher(isLogin: false),
            ],
          ),
        ),
      ),
    );
  }
}
