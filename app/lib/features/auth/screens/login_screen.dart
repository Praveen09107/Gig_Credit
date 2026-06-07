import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/inputs/phone_input_field.dart';
import '../../../shared/widgets/buttons/primary_button.dart';
import '../../../shared/widgets/status/inline_message_banner.dart';
import '../../../shared/widgets/feedback/app_toast.dart';
import '../controllers/auth_controller.dart';
import '../../../app/app_router.dart';

/// GigCredit Sign In Screen
/// Green gradient top band → white form card → Send OTP → switch to signup
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _mobileController = TextEditingController();
  bool _isMobileValid = false;
  String? _errorMsg;

  late AnimationController _enterController;
  late Animation<double> _bandFade;
  late Animation<Offset> _cardSlide;
  late Animation<double> _cardFade;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _bandFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _enterController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));

    _cardFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );

    _enterController.forward();
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _enterController.dispose();
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
    final responseStr =
        await ref.read(authControllerProvider.notifier).sendOtp(mobile);

    // Check if it's a 6-digit OTP (success) or a successful Twilio response
    if (responseStr != null &&
        (RegExp(r'^\d{6}$').hasMatch(responseStr) ||
            responseStr == 'TWILIO_SUCCESS') &&
        mounted) {
      debugPrint('[GigCredit] OTP Generated: $responseStr');

      // Show premium toast notification
      AppToast.success(context, 'OTP Sent',
          subtitle: 'Check your messages for the 6-digit code.');

      // Also show OTP in a subtle way for demo purposes ONLY if not Twilio
      if (mounted && responseStr != 'TWILIO_SUCCESS') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Your OTP: $responseStr',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: AppColors.greenPrimary,
            duration: const Duration(seconds: 8),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      context.push('${AppRoutes.otp}?mobile=$mobile&isSignup=false');
    } else {
      // Strip ERROR: prefix returned by AuthController on exception
      final errorMsg = responseStr?.startsWith('ERROR:') == true
          ? responseStr!.substring(6)
          : (responseStr ?? 'Failed to send OTP');

      // Map backend error codes to user-friendly messages
      if (errorMsg.contains('not_found') ||
          errorMsg.contains('No account') ||
          errorMsg.contains('sign up first')) {
        AppToast.error(context, 'No account found',
            subtitle: 'This number is not registered. Please sign up first.');
      } else if (errorMsg.contains('Network') ||
          errorMsg.contains('SocketException') ||
          errorMsg.contains('Connection refused')) {
        AppToast.error(context, 'Network Error',
            subtitle: 'Please check your connection and try again.');
      } else if (errorMsg.contains('too many') ||
          errorMsg.contains('limit') ||
          errorMsg.contains('max_attempts')) {
        AppToast.error(context, 'Too many attempts',
            subtitle: 'Please wait a moment and try again.');
      } else if (errorMsg.contains('invalid_format')) {
        AppToast.error(context, 'Invalid number',
            subtitle: 'Enter a valid 10-digit Indian mobile number.');
      } else {
        AppToast.error(context, 'Failed to send OTP',
            subtitle: 'Please try again.');
      }
      setState(() => _errorMsg = errorMsg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.greenPrimary,
              AppColors.greenMid,
              Color(0xFFE8F5E9),
              AppColors.bgScreen,
            ],
            stops: [0.0, 0.25, 0.45, 0.65],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: screenHeight -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                children: [
                  // ── Brand Band ─────────────────────────────────────
                  FadeTransition(
                    opacity: _bandFade,
                    child: _buildBrandBand(),
                  ),

                  // ── Form Card ──────────────────────────────────────
                  SlideTransition(
                    position: _cardSlide,
                    child: FadeTransition(
                      opacity: _cardFade,
                      child: _buildFormCard(isLoading),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandBand() {
    return Padding(
      padding: const EdgeInsets.only(top: 48, bottom: 32),
      child: Column(
        children: [
          // Real GigCredit logo
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.asset(
                'assets/images/app_logo.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'GigCredit',
            style: AppTypography.displayMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Welcome back',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.80),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(bool isLoading) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Text(
            'Sign In',
            style: AppTypography.headlineLarge.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your mobile number to continue',
            style: AppTypography.bodyMedium.copyWith(fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // Error banner
          if (_errorMsg != null) ...[
            InlineMessageBanner(message: _errorMsg!),
            const SizedBox(height: 16),
          ],

          // Phone input
          PhoneInputField(
            controller: _mobileController,
            onChanged: _validate,
          ),

          const SizedBox(height: 28),

          // Send OTP
          PrimaryButton(
            label: 'SEND OTP',
            isLoading: isLoading,
            isDisabled: !_isMobileValid,
            onPressed: _handleLogin,
            suffixIcon: const Icon(Icons.arrow_forward_rounded,
                color: Colors.white, size: 18),
          ),

          const SizedBox(height: 24),

          // Divider
          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.borderCard)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OR',
                  style: AppTypography.caption.copyWith(fontSize: 12),
                ),
              ),
              const Expanded(child: Divider(color: AppColors.borderCard)),
            ],
          ),

          const SizedBox(height: 20),

          // Switch to signup
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an account?  ",
                style: AppTypography.bodyMedium.copyWith(fontSize: 14),
              ),
              GestureDetector(
                onTap: () => context.go(AppRoutes.signup),
                child: Text(
                  'Sign Up',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.greenPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
