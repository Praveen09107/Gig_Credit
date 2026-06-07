import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/inputs/phone_input_field.dart';
import '../../../shared/widgets/inputs/app_text_field.dart';
import '../../../shared/widgets/buttons/primary_button.dart';
import '../../../shared/widgets/status/inline_message_banner.dart';
import '../../../shared/widgets/feedback/app_toast.dart';
import '../controllers/auth_controller.dart';
import '../../../app/app_router.dart';

/// GigCredit Sign Up Screen
/// Light gradient bg → brand name + tagline → white form card
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isValid = false;
  String? _errorMsg;

  late AnimationController _enterController;
  late Animation<double> _brandFade;
  late Animation<Offset> _cardSlide;
  late Animation<double> _cardFade;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _brandFade = Tween<double>(begin: 0, end: 1).animate(
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
    _nameController.dispose();
    _enterController.dispose();
    super.dispose();
  }

  void _validate() {
    setState(() {
      _isValid = _mobileController.text.length == 10 &&
          _nameController.text.length >= 2;
      _errorMsg = null;
    });
  }

  Future<void> _handleSignup() async {
    final mobile = _mobileController.text;
    final name = _nameController.text;
    final responseStr = await ref
        .read(authControllerProvider.notifier)
        .sendOtp(mobile, isSignup: true, name: name);

    // Check if it's a 6-digit OTP (success) or a successful Twilio response
    if (responseStr != null &&
        (RegExp(r'^\d{6}$').hasMatch(responseStr) ||
            responseStr == 'TWILIO_SUCCESS') &&
        mounted) {
      debugPrint('[GigCredit] OTP Generated: $responseStr');

      // Show premium toast notification
      AppToast.success(context, 'OTP Sent',
          subtitle: 'Check your messages for the 6-digit code.');

      // Show OTP for demo ONLY if not Twilio
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
      context.push('${AppRoutes.otp}?mobile=$mobile&isSignup=true');
    } else {
      // Strip ERROR: prefix returned by AuthController on exception
      final errorMsg = responseStr?.startsWith('ERROR:') == true
          ? responseStr!.substring(6)
          : (responseStr ?? 'Registration failed');

      if (errorMsg.contains('already_exists') ||
          errorMsg.contains('exists') ||
          errorMsg.contains('already') ||
          errorMsg.contains('in use')) {
        AppToast.error(context, 'Account already exists',
            subtitle: 'This number is already registered. Please sign in.');
      } else if (errorMsg.contains('Network') ||
          errorMsg.contains('SocketException') ||
          errorMsg.contains('Connection refused')) {
        AppToast.error(context, 'Network Error',
            subtitle: 'Please check your connection and try again.');
      } else if (errorMsg.contains('invalid_format')) {
        AppToast.error(context, 'Invalid number',
            subtitle: 'Enter a valid 10-digit Indian mobile number.');
      } else {
        AppToast.error(context, 'Registration failed',
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
              Color(0xFFE8F5E9),
              Color(0xFFF0F8F2),
              AppColors.bgScreen,
            ],
            stops: [0.0, 0.4, 0.7],
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
                  // ── Brand Header ───────────────────────────────────
                  FadeTransition(
                    opacity: _brandFade,
                    child: _buildBrandHeader(),
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

                  // Switch to sign in
                  FadeTransition(
                    opacity: _cardFade,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account?  ',
                          style:
                              AppTypography.bodyMedium.copyWith(fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () => context.go(AppRoutes.login),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Sign In',
                                style: AppTypography.labelLarge.copyWith(
                                  color: AppColors.greenPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_rounded,
                                  size: 16, color: AppColors.greenPrimary),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 48, bottom: 28),
      child: Column(
        children: [
          // Real GigCredit logo
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.greenPrimary.withValues(alpha: 0.20),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/app_logo.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'GigCredit',
            style: AppTypography.displayMedium.copyWith(
              color: AppColors.greenPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 32,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Create your account',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
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
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 28,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Text(
            'Sign Up',
            style: AppTypography.headlineLarge.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 24),

          // Error banner
          if (_errorMsg != null) ...[
            InlineMessageBanner(message: _errorMsg!),
            const SizedBox(height: 16),
          ],

          // Name field
          AppTextField(
            label: 'Full Name',
            hint: 'Enter your full name',
            controller: _nameController,
            onChanged: (_) => _validate(),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 14, right: 10),
              child: Icon(Icons.person_outline_rounded,
                  size: 20, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 16),

          // Phone field
          PhoneInputField(
            controller: _mobileController,
            onChanged: (_) => _validate(),
          ),
          const SizedBox(height: 28),

          // Send OTP
          PrimaryButton(
            label: 'SEND OTP',
            isLoading: isLoading,
            isDisabled: !_isValid,
            onPressed: _handleSignup,
          ),
        ],
      ),
    );
  }
}
