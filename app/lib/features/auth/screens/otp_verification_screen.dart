import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/inputs/otp_input_widget.dart';
import '../../../shared/widgets/inputs/otp_resend_timer.dart';
import '../../../shared/widgets/buttons/primary_button.dart';
import '../../../shared/widgets/status/inline_message_banner.dart';
import '../controllers/auth_controller.dart';
import '../../../state/auth_provider.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String mobile;
  final bool isSignup;

  const OtpVerificationScreen({
    super.key,
    required this.mobile,
    this.isSignup = false,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  String _otp = '';
  
  Future<void> _verifyOtp() async {
    final success = await ref.read(authControllerProvider.notifier).verifyOtp(widget.mobile, _otp);
    if (success && mounted) {
      context.go('/app/home');
    }
  }

  void _resendOtp() {
    ref.read(authControllerProvider.notifier).sendOtp(widget.mobile, isSignup: widget.isSignup);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      Text('Verify Mobile', style: AppTypography.displayMedium),
                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          style: AppTypography.bodyMedium,
                          children: [
                            const TextSpan(text: 'Enter the 6-digit OTP sent to '),
                            TextSpan(
                              text: '+91 ${widget.mobile}',
                              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),

                      if (authState.errorMessage != null) ...[
                        InlineMessageBanner(message: authState.errorMessage!),
                        const SizedBox(height: 24),
                      ],

                      OtpInputWidget(
                        length: 6,
                        onChanged: (val) => setState(() => _otp = val),
                        onCompleted: (val) {
                          setState(() => _otp = val);
                          _verifyOtp();
                        },
                      ),
                      const SizedBox(height: 32),

                      Center(
                        child: OtpResendTimer(
                          durationSeconds: 30,
                          onResend: _resendOtp,
                        ),
                      ),
                      
                      const Spacer(),
                      
                      PrimaryButton(
                        label: 'Verify & Proceed',
                        isLoading: isLoading,
                        isDisabled: _otp.length < 6,
                        onPressed: _verifyOtp,
                      ),
                      const SizedBox(height: 24),
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
