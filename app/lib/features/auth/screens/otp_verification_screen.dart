import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/inputs/otp_input_widget.dart';
import '../../../shared/widgets/inputs/otp_resend_timer.dart';
import '../../../shared/widgets/buttons/primary_button.dart';
import '../../../shared/widgets/status/inline_message_banner.dart';
import '../../../shared/widgets/feedback/toast_service.dart';
import '../../../shared/widgets/feedback/toast_types.dart';
import '../controllers/auth_controller.dart';
import '../../../state/auth_provider.dart';

/// GigCredit OTP Verification Screen
/// Green-accent header with shield icon, 6-box OTP input, verify CTA
class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String mobile;
  final bool isSignup;

  const OtpVerificationScreen({
    super.key,
    required this.mobile,
    this.isSignup = false,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState
    extends ConsumerState<OtpVerificationScreen>
    with SingleTickerProviderStateMixin {
  String _otp = '';

  late AnimationController _enterController;
  late Animation<double> _headerFade;
  late Animation<Offset> _contentSlide;
  late Animation<double> _contentFade;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _headerFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _enterController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));

    _contentFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );

    _enterController.forward();
  }

  @override
  void dispose() {
    _enterController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    final success = await ref
        .read(authControllerProvider.notifier)
        .verifyOtp(widget.mobile, _otp);
    if (success && mounted) {
      // Show success toast
      if (widget.isSignup) {
        globalToastService.showById(ToastId.accountCreated);
      } else {
        globalToastService.showById(ToastId.signinSuccess);
      }
      context.go('/app/home');
    } else if (mounted) {
      // Show error toast
      final authState = ref.read(authProvider);
      final error = authState.errorMessage ?? '';
      if (error.contains('expired')) {
        globalToastService.showById(ToastId.otpExpired);
      } else {
        globalToastService.showById(ToastId.otpIncorrect);
      }
    }
  }

  void _resendOtp() {
    ref
        .read(authControllerProvider.notifier)
        .sendOtp(widget.mobile, isSignup: widget.isSignup);
    globalToastService.showById(ToastId.otpResent);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.bgScreen,
      appBar: AppBar(
        backgroundColor: AppColors.bgCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.greenPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Verify Mobile',
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),

              // ── Shield icon + heading ────────────────────────────
              FadeTransition(
                opacity: _headerFade,
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.greenPrimary, AppColors.greenBright],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.greenBright.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.shield_outlined,
                          color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Enter Verification Code',
                      style: AppTypography.headlineLarge.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: AppTypography.bodyMedium.copyWith(
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(text: 'We sent a 6-digit code to\n'),
                          TextSpan(
                            text: '+91 ${widget.mobile}',
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.greenPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // ── Error ────────────────────────────────────────────
              if (authState.errorMessage != null) ...[
                InlineMessageBanner(message: authState.errorMessage!),
                const SizedBox(height: 20),
              ],

              // ── OTP Input Boxes ──────────────────────────────────
              SlideTransition(
                position: _contentSlide,
                child: FadeTransition(
                  opacity: _contentFade,
                  child: Column(
                    children: [
                      OtpInputWidget(
                        length: 6,
                        onChanged: (val) => setState(() => _otp = val),
                        onCompleted: (val) {
                          setState(() => _otp = val);
                          _verifyOtp();
                        },
                      ),
                      const SizedBox(height: 28),

                      // Resend timer
                      Center(
                        child: OtpResendTimer(
                          durationSeconds: 30,
                          onResend: _resendOtp,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Verify button
                      PrimaryButton(
                        label: 'VERIFY & PROCEED',
                        isLoading: isLoading,
                        isDisabled: _otp.length < 6,
                        onPressed: _verifyOtp,
                        suffixIcon: const Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
