import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/buttons/primary_button.dart';
import '../../../app/app_router.dart';
import '../widgets/step_square_card.dart';

/// GigCredit "How It Works" Screen
/// Green hero → 9-step grid → Start CTA
class ShowMeHowScreen extends StatelessWidget {
  const ShowMeHowScreen({super.key});

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
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.greenPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('How It Works',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
            centerTitle: true,
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                // Hero
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  decoration: const BoxDecoration(gradient: AppColors.heroGradient),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🔍  9-Step Verification',
                          style: AppTypography.eyebrow.copyWith(fontSize: 13)),
                      const SizedBox(height: 8),
                      Text('The Process',
                          style: AppTypography.heroHeading.copyWith(fontSize: 24)),
                      const SizedBox(height: 6),
                      Text(
                        'We use 7 distinct pillars of verified data to build an accurate AI credit profile for you.',
                        style: AppTypography.heroBody,
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms),

                const SizedBox(height: 20),

                // Grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      StepSquareCard(stepNumber: 1, title: 'Personal Info', icon: Icons.person_outline, onTap: () {}),
                      StepSquareCard(stepNumber: 2, title: 'KYC Checks', icon: Icons.badge_outlined, onTap: () {}),
                      StepSquareCard(stepNumber: 3, title: 'Bank Info', icon: Icons.account_balance, onTap: () {}),
                      StepSquareCard(stepNumber: 4, title: 'Utilities', icon: Icons.bolt, onTap: () {}),
                      StepSquareCard(stepNumber: 5, title: 'Work History', icon: Icons.work_outline, onTap: () {}),
                      StepSquareCard(stepNumber: 6, title: 'Gov Schemes', icon: Icons.gavel, onTap: () {}),
                      StepSquareCard(stepNumber: 7, title: 'Insurance', icon: Icons.health_and_safety_outlined, onTap: () {}),
                      StepSquareCard(stepNumber: 8, title: 'Tax Details', icon: Icons.receipt_long, onTap: () {}),
                      StepSquareCard(stepNumber: 9, title: 'EMI & Loans', icon: Icons.credit_score, onTap: () {}),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: PrimaryButton(
                    label: 'START NOW',
                    onPressed: () => context.push(AppRoutes.scoreStep(1)),
                    suffixIcon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.05),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
