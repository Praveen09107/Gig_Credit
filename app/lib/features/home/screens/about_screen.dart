import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/cards/app_card.dart';

/// GigCredit About Screen
/// Green hero header, feature cards, flow diagram
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgScreen,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppColors.bgCard,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded,
                  color: AppColors.greenPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'About GigCredit',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                // ── Hero Band ────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 36),
                  decoration: const BoxDecoration(gradient: AppColors.heroGradient),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25), width: 2),
                        ),
                        child: const Icon(Icons.shield_rounded,
                            size: 42, color: Colors.white),
                      ).animate()
                          .scale(duration: 500.ms, curve: Curves.easeOutBack),
                      const SizedBox(height: 18),
                      Text(
                        'Redefining Trust for\nthe Gig Economy',
                        style: AppTypography.heroHeading.copyWith(fontSize: 26),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 150.ms),
                      const SizedBox(height: 12),
                      Text(
                        'Privacy-first, on-device credit scoring built for gig workers, freelancers, and street vendors.',
                        style: AppTypography.heroBody,
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 250.ms),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Core Philosophy ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CORE PHILOSOPHY',
                          style: AppTypography.sectionLabel),
                      const SizedBox(height: 16),
                      const _FeatureCard(
                        icon: Icons.lock_rounded,
                        iconColor: AppColors.greenPrimary,
                        title: '100% Privacy',
                        desc: 'Your data never leaves your device. We use advanced on-device ML models to compute scores locally.',
                        delay: 300,
                      ),
                      const _FeatureCard(
                        icon: Icons.auto_graph_rounded,
                        iconColor: AppColors.pillar5,
                        title: 'Alternative Data',
                        desc: 'We look beyond CIBIL. We evaluate utility payments, government schemes, and work history.',
                        delay: 380,
                      ),
                      const _FeatureCard(
                        icon: Icons.lightbulb_rounded,
                        iconColor: AppColors.warning,
                        title: 'Explainable AI',
                        desc: 'SHAP-based explanations so you know exactly why you got your score and how to improve it.',
                        delay: 460,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── How It Works ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('HOW IT WORKS',
                          style: AppTypography.sectionLabel),
                      const SizedBox(height: 16),
                      const _FlowStep(
                        number: '1',
                        title: 'Data Collection',
                        desc: 'Upload Aadhaar, PAN, Bank Statements, and Work Proofs directly on your phone.',
                        delay: 540,
                      ),
                      const _FlowConnector(delay: 600),
                      const _FlowStep(
                        number: '2',
                        title: 'On-Device Verification',
                        desc: 'Our Edge AI extracts and validates your documents instantly without cloud servers.',
                        delay: 660,
                      ),
                      const _FlowConnector(delay: 720),
                      const _FlowStep(
                        number: '3',
                        title: '7-Pillar Scoring Engine',
                        desc: 'An XGBoost Meta-Learner evaluates income, debts, savings, and compliance.',
                        delay: 780,
                      ),
                      const _FlowConnector(delay: 840),
                      const _FlowStep(
                        number: '4',
                        title: 'Credit Report & Offers',
                        desc: 'Instantly receive your Grade and tailored micro-loan offers from partner lenders.',
                        delay: 900,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, desc;
  final int delay;

  const _FeatureCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.desc,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTypography.titleSmall
                          .copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(desc,
                      style: AppTypography.bodySmall.copyWith(height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate()
        .fadeIn(delay: Duration(milliseconds: delay))
        .slideX(begin: 0.08, duration: 400.ms, curve: Curves.easeOutCubic);
  }
}

class _FlowStep extends StatelessWidget {
  final String number, title, desc;
  final int delay;

  const _FlowStep({
    required this.number,
    required this.title,
    required this.desc,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppColors.ctaGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: AppTypography.labelLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTypography.titleSmall
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(desc,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    )),
              ],
            ),
          ),
        ],
      ),
    ).animate()
        .scale(
            delay: Duration(milliseconds: delay),
            duration: 400.ms,
            curve: Curves.easeOutBack);
  }
}

class _FlowConnector extends StatelessWidget {
  final int delay;
  const _FlowConnector({required this.delay});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 24,
        width: 2,
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.greenBright.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay));
  }
}
