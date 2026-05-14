import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../state/user_provider.dart';
import '../../../state/score_provider.dart';
import '../../../app/app_router.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/hero_image_slider.dart';

/// GigCredit Home Screen — Full spec implementation
/// TopBar → HeroBand → FloatingCarousel → GetStarted → QuickAccess → Footer
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final scoreState = ref.watch(scoreProvider);
    final hasScore = scoreState.reportData != null;

    return Scaffold(
      backgroundColor: AppColors.bgScreen,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(dashboardControllerProvider.notifier).refreshAll(),
          color: AppColors.greenPrimary,
          child: CustomScrollView(
            slivers: [
              // ── Sticky Top Bar ─────────────────────────────────────
              SliverAppBar(
                floating: true,
                snap: true,
                elevation: 0,
                scrolledUnderElevation: 1,
                surfaceTintColor: Colors.transparent,
                backgroundColor: AppColors.bgCard,
                toolbarHeight: 56,
                systemOverlayStyle: const SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.dark,
                ),
                title: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      // Brand icon
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.greenPrimary,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(color: AppColors.greenPrimary.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 1)
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'G',
                          style: AppTypography.labelLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 2.seconds, color: Colors.white24),
                      const SizedBox(width: 8),
                      Text('GigCredit', style: AppTypography.brandName),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
                actions: [
                  // Nav pills
                  _NavPill(
                    label: 'About',
                    onTap: () => context.push(AppRoutes.about),
                  ),
                  const SizedBox(width: 4),
                  _NavPill(
                    label: 'Schemes',
                    onTap: () => context.push(AppRoutes.schemes),
                  ),
                  const SizedBox(width: 8),
                  // Profile avatar
                  GestureDetector(
                    onTap: () => context.go(AppRoutes.profile),
                    child: Container(
                      width: 36,
                      height: 36,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.greenMuted,
                        border: Border.all(
                            color: AppColors.greenPrimary, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.person_rounded,
                          size: 18, color: AppColors.greenPrimary),
                    ),
                  ),
                ],
              ),

              // ── Content ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // HERO BAND
                    _HeroBand().animate().fadeIn(duration: 500.ms),

                    const SizedBox(height: 24),

                    // SECTION: Trusted by gig workers
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Trusted by gig workers across India',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 12),

                    // Image carousel
                    const HeroImageSlider()
                        .animate()
                        .fadeIn(delay: 300.ms),

                    const SizedBox(height: 32),

                    // GET STARTED BUTTON
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _GetStartedButton(
                        hasScore: hasScore,
                        onTap: () {
                          if (hasScore) {
                            context.push(AppRoutes.scoreReport);
                          } else {
                            _showGetStartedPopup(context);
                          }
                        },
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.05),

                    const SizedBox(height: 32),

                    // QUICK ACCESS
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'QUICK ACCESS',
                        style: AppTypography.sectionLabel,
                      ),
                    ).animate().fadeIn(delay: 500.ms),

                    const SizedBox(height: 4),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Divider(color: AppColors.borderCard),
                    ),
                    const SizedBox(height: 16),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: _QuickAccessCard(
                              icon: Icons.history_rounded,
                              label: 'History',
                              onTap: () => context.go(AppRoutes.applications),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickAccessCard(
                              icon: Icons.article_outlined,
                              label: 'Guidelines',
                              isAccent: true,
                              onTap: () => context.push('/app/guidance'),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 600.ms),

                    const SizedBox(height: 40),

                    // FOOTER
                    _AppFooter(),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGetStartedPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xA60D1F15),
      builder: (ctx) => const _GetStartedSheet(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HERO BAND
// ═══════════════════════════════════════════════════════════════════════════

class _HeroBand extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 36),
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: Stack(
        children: [
          // Floating Particles
          const Positioned.fill(child: _FloatingParticles()),

          // Decorative animated orbs
          Positioned(
            top: -50,
            right: -50,
            child: _AnimatedOrb(
              size: 200,
              color: Colors.white.withValues(alpha: 0.07),
              duration: const Duration(seconds: 12),
              offset: const Offset(-10, 10),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -30,
            child: _AnimatedOrb(
              size: 130,
              color: Colors.white.withValues(alpha: 0.04),
              duration: const Duration(seconds: 9),
              offset: const Offset(8, -8),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Eyebrow chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.28)),
                ),
                child: Text(
                  "🏆  India's Credit Platform for Gig Workers",
                  style: AppTypography.eyebrow,
                ),
              ).animate().fadeIn(duration: 450.ms).slideX(begin: -0.05),

              const SizedBox(height: 16),

              // Heading
              RichText(
                text: TextSpan(
                  style: AppTypography.heroHeading,
                  children: const [
                    TextSpan(text: 'Build Credit.\nUnlock '),
                    TextSpan(
                      text: 'Better Loans.',
                      style: TextStyle(color: AppColors.greenMint),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 80.ms, duration: 500.ms).slideY(begin: 0.05),

              const SizedBox(height: 12),

              // Body
              Text(
                'GigCredit uses your real income signals — bank statements, UPI history, and gig platform data — to give platform workers fair, fast access to credit.',
                style: AppTypography.heroBody,
              ).animate().fadeIn(delay: 160.ms, duration: 500.ms).slideY(begin: 0.04),

              const SizedBox(height: 24),

              // Stats row
              Row(
                children: [
                  _StatBlock(number: '15M+', label: 'Gig Workers'),
                  _StatDivider(),
                  _StatBlock(number: '₹82K', label: 'Avg Loan'),
                  _StatDivider(),
                  _StatBlock(number: 'Grade B+', label: 'Avg Score'),
                ],
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String number;
  final String label;
  const _StatBlock({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(number, style: AppTypography.statNumber),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.statLabel),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: Colors.white.withValues(alpha: 0.25),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ANIMATED ORBS & PARTICLES
// ═══════════════════════════════════════════════════════════════════════════

class _AnimatedOrb extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;
  final Offset offset;

  const _AnimatedOrb({
    required this.size,
    required this.color,
    required this.duration,
    required this.offset,
  });

  @override
  State<_AnimatedOrb> createState() => _AnimatedOrbState();
}

class _AnimatedOrbState extends State<_AnimatedOrb>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 1.0 + (_controller.value * 0.15);
        final dx = _controller.value * widget.offset.dx;
        final dy = _controller.value * widget.offset.dy;
        return Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.scale(
            scale: scale,
            child: child,
          ),
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
      ),
    );
  }
}

class _FloatingParticles extends StatefulWidget {
  const _FloatingParticles();

  @override
  State<_FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<_FloatingParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(seconds: 10))
      ..repeat();

    // Generate 20 particles
    for (int i = 0; i < 20; i++) {
      _particles.add(_Particle());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _ParticlePainter(_particles, _controller.value),
        );
      },
    );
  }
}

class _Particle {
  final double xStart;
  final double yStart;
  final double size;
  final double speed;
  final double opacity;
  final double drift;

  _Particle()
      : xStart = (DateTime.now().microsecondsSinceEpoch % 100) / 100.0,
        yStart = ((DateTime.now().microsecondsSinceEpoch * 7) % 100) / 100.0,
        size = 2.0 + ((DateTime.now().microsecondsSinceEpoch * 13) % 40) / 10.0, // 2-6px
        speed = 0.5 + ((DateTime.now().microsecondsSinceEpoch * 17) % 100) / 100.0,
        opacity = 0.15 + ((DateTime.now().microsecondsSinceEpoch * 19) % 20) / 100.0, // 0.15-0.35
        drift = ((DateTime.now().microsecondsSinceEpoch * 23) % 100 - 50) / 50.0; // -1 to 1
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (var p in particles) {
      // Calculate current position based on continuous progress
      // progress goes from 0 to 1 over 10 seconds.
      // A particle takes roughly 1/speed loops to cross the screen.
      final totalDist = size.height + 50;
      double yOffset = (progress * 2 * p.speed * totalDist + p.yStart * totalDist) % totalDist;
      
      final y = size.height - yOffset + 20; // Float upwards
      
      // Drift sideways using a sine wave
      final xDrift = math.sin((progress * math.pi * 4 * p.speed) + (p.xStart * math.pi * 2)) * 15 * p.drift;
      final x = (p.xStart * size.width) + xDrift;

      paint.color = AppColors.greenMint.withValues(alpha: p.opacity);
      canvas.drawCircle(Offset(x, y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// GET STARTED BUTTON
// ═══════════════════════════════════════════════════════════════════════════

class _GetStartedButton extends StatefulWidget {
  final bool hasScore;
  final VoidCallback onTap;
  const _GetStartedButton({required this.hasScore, required this.onTap});

  @override
  State<_GetStartedButton> createState() => _GetStartedButtonState();
}

class _GetStartedButtonState extends State<_GetStartedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) {
              setState(() => _pressed = false);
              HapticFeedback.mediumImpact();
              widget.onTap();
            },
            onTapCancel: () => setState(() => _pressed = false),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: AppColors.ctaGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.greenBright.withValues(
                        alpha: 0.35 + (_pulseController.value * 0.2)),
                    blurRadius: 20 + (_pulseController.value * 12),
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.hasScore ? '🎯' : '🚀',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.hasScore ? 'VIEW SCORE' : 'GET STARTED',
                    style: AppTypography.button.copyWith(
                      fontSize: 16,
                      letterSpacing: 0.8,
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

// ═══════════════════════════════════════════════════════════════════════════
// QUICK ACCESS CARD
// ═══════════════════════════════════════════════════════════════════════════

class _QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isAccent;

  const _QuickAccessCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bgCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: AppColors.greenMuted.withValues(alpha: 0.3),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isAccent
                  ? AppColors.greenBright.withValues(alpha: 0.3)
                  : AppColors.borderCard,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: isAccent
                      ? AppColors.greenPrimary
                      : AppColors.textMuted),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.labelLarge.copyWith(
                  color: isAccent
                      ? AppColors.greenPrimary
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// NAV PILL (top bar)
// ═══════════════════════════════════════════════════════════════════════════

class _NavPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NavPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.borderCard),
        ),
        child: Text(
          label,
          style: AppTypography.navPill,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GET STARTED BOTTOM SHEET (Popup spec)
// ═══════════════════════════════════════════════════════════════════════════

class _GetStartedSheet extends StatelessWidget {
  const _GetStartedSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            const SizedBox(height: 14),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderCard,
                borderRadius: BorderRadius.circular(999),
              ),
            ),

            const SizedBox(height: 24),

            // Icon hero
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.greenBright.withValues(alpha: 0.20),
                  width: 2,
                ),
              ),
              child: Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: AppColors.ctaGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.greenBright.withValues(alpha: 0.38),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🚀', style: TextStyle(fontSize: 36)),
                  ),
                ),
              ),
            ).animate().scale(
                  begin: const Offset(0, 0),
                  end: const Offset(1, 1),
                  duration: 400.ms,
                  curve: Curves.easeOutBack,
                  delay: 80.ms,
                ),

            const SizedBox(height: 20),

            // Heading
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: AppTypography.displaySmall.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
                children: [
                  const TextSpan(text: 'Ready to Start Your\n'),
                  TextSpan(
                    text: 'Credit Journey?',
                    style: TextStyle(color: AppColors.greenPrimary),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 160.ms).slideY(begin: 0.06),

            const SizedBox(height: 10),

            // Subtext
            Text(
              "We'll check your eligibility in minutes\nusing your income data — no CIBIL needed.",
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                height: 1.65,
                fontSize: 14,
              ),
            ).animate().fadeIn(delay: 220.ms).slideY(begin: 0.04),

            const SizedBox(height: 20),

            // Feature chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _FeatureChip(label: '⚡  Fast Approval'),
                _FeatureChip(label: '🔒  Secure'),
                _FeatureChip(label: '📄  No CIBIL'),
              ],
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 24),

            const Divider(color: AppColors.borderCard),

            const SizedBox(height: 24),

            // Continue button
            _PopupContinueButton(
              onTap: () {
                Navigator.pop(context);
                context.go(AppRoutes.score);
              },
            ).animate().fadeIn(delay: 380.ms).slideY(begin: 0.04),

            const SizedBox(height: 12),

            // Guidelines button
            _PopupGuidelinesButton(
              onTap: () {
                Navigator.pop(context);
                context.push('/app/guidance');
              },
            ).animate().fadeIn(delay: 440.ms).slideY(begin: 0.04),

            const SizedBox(height: 16),

            // Dismiss hint
            Text(
              'Swipe down or tap outside to close',
              style: AppTypography.caption.copyWith(fontSize: 11),
            ).animate().fadeIn(delay: 520.ms),
          ],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String label;
  const _FeatureChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.greenMuted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
            color: AppColors.greenBright.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: AppTypography.chip.copyWith(color: AppColors.greenPrimary),
      ),
    );
  }
}

class _PopupContinueButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PopupContinueButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: AppColors.ctaGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.greenBright.withValues(alpha: 0.42),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('CONTINUE',
                style: AppTypography.button
                    .copyWith(letterSpacing: 0.6, fontSize: 16)),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward_rounded,
                color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}

class _PopupGuidelinesButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PopupGuidelinesButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderCard, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📋', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Text(
              'View Guidelines First',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// APP FOOTER
// ═══════════════════════════════════════════════════════════════════════════

class _AppFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      color: AppColors.greenPrimary.withValues(alpha: 0.06),
      child: Column(
        children: [
          // Brand
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.greenPrimary,
                  borderRadius: BorderRadius.circular(7),
                ),
                alignment: Alignment.center,
                child: Text(
                  'G',
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'GigCredit',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Empowering India's Gig Economy",
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.borderCard),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _FooterLink(label: 'Privacy Policy'),
              _FooterDot(),
              _FooterLink(label: 'Terms'),
              _FooterDot(),
              _FooterLink(label: 'Support'),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '© 2026 GigCredit. All rights reserved.',
            style: AppTypography.caption.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  const _FooterLink({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.labelMedium.copyWith(
        color: AppColors.textMuted,
        fontSize: 12,
      ),
    );
  }
}

class _FooterDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        width: 3,
        height: 3,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
