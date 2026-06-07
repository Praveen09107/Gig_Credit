import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/app_router.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../state/auth_provider.dart';
import '../../../state/user_provider.dart';
import '../../../models/user_model.dart';
import '../../../services/session_service.dart';

/// GigCredit Splash Screen — Loader 3D from spec
/// Full green gradient bg, animated G icon, loading bar, tagline
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _iconController;
  late AnimationController _barController;
  late AnimationController _fadeController;

  late Animation<double> _iconScale;
  late Animation<double> _barWidth;
  late Animation<double> _titleOpacity;
  late Animation<Offset> _titleSlide;
  late Animation<double> _taglineOpacity;

  @override
  void initState() {
    super.initState();

    // Set status bar to light (white icons on green)
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // Icon: spring scale in
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _iconScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.1), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.easeOut,
    ));

    // Title fade + slide
    _titleOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    ));

    // Tagline fade
    _taglineOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    // Loading bar fills over 1.8s
    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _barWidth = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _barController, curve: Curves.easeInOut),
    );

    // Fade out
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _iconController.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _barController.forward();

    // Wait for bar to fill
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    // Fade out
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    // Try to restore session from secure storage
    // Wrapped in try-catch: flutter_secure_storage may throw on web
    Map<String, String>? session;
    try {
      session = await SessionService.loadSession();
    } catch (e) {
      debugPrint('[Session] Could not load session: $e');
      session = null;
    }
    if (!mounted) return;

    // Navigate after a short delay to fully escape build/dispose cycles.
    // This avoids _dependents.isEmpty assertion from GoRouter redirect
    // firing while the splash widget tree is still being torn down.
    await Future.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;

    if (session != null) {
      // Restore user into providers
      final user = UserModel(
        id: session['userId'] ?? '',
        name: session['name'] ?? '',
        mobile: session['mobile'] ?? '',
        isVerified: true,
      );
      ref.read(userProvider.notifier).setUser(user);
      ref.read(authProvider.notifier).setAuthenticated(
            userId: user.id,
            token: session['token'] ?? '',
          );
      if (mounted) context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _iconController.dispose();
    _barController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        return Opacity(
          opacity: 1.0 - _fadeController.value,
          child: Scaffold(
            body: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-0.7, -0.5),
                  end: Alignment(0.7, 0.8),
                  colors: [
                    AppColors.greenPrimary,
                    AppColors.greenMid,
                    AppColors.greenBright,
                  ],
                  stops: [0.0, 0.6, 1.0],
                ),
              ),
              child: Stack(
                children: [
                  // Decorative circles
                  Positioned(
                    top: -80,
                    right: -60,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -40,
                    left: -50,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.04),
                      ),
                    ),
                  ),

                  // Main content
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // App Icon — real GigCredit logo
                        AnimatedBuilder(
                          animation: _iconScale,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _iconScale.value,
                              child: Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.25),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Image.asset(
                                    'assets/images/app_logo.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        // App Name
                        SlideTransition(
                          position: _titleSlide,
                          child: FadeTransition(
                            opacity: _titleOpacity,
                            child: Text(
                              'GigCredit',
                              style: AppTypography.displayLarge.copyWith(
                                color: Colors.white,
                                fontSize: 30,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Tagline
                        FadeTransition(
                          opacity: _taglineOpacity,
                          child: Text(
                            'Credit for every worker',
                            style: AppTypography.bodyMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.70),
                              fontSize: 14,
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Loading bar
                        AnimatedBuilder(
                          animation: _barWidth,
                          builder: (context, child) {
                            return Container(
                              width: 160,
                              height: 3,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: Colors.white.withValues(alpha: 0.20),
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  width: 160 * _barWidth.value,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    color: AppColors.greenMint,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.greenMint
                                            .withValues(alpha: 0.60),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
