import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/buttons/primary_button.dart';
import '../../../app/app_router.dart';
import '../widgets/step_square_card.dart';

class ShowMeHowScreen extends StatelessWidget {
  const ShowMeHowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How it Works'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The 9-Step Verification',
              style: AppTypography.displaySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'We use 7 distinct pillars of verified data to build an accurate AI credit profile for you. Tap a step to learn more.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 24),
            
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                StepSquareCard(
                  stepNumber: 1, title: 'Personal Info', icon: Icons.person_outline, onTap: () {}
                ),
                StepSquareCard(
                  stepNumber: 2, title: 'KYC Checks', icon: Icons.badge_outlined, onTap: () {}
                ),
                StepSquareCard(
                  stepNumber: 3, title: 'Bank Info', icon: Icons.account_balance, onTap: () {}
                ),
                StepSquareCard(
                  stepNumber: 4, title: 'Utilities', icon: Icons.bolt, onTap: () {}
                ),
                StepSquareCard(
                  stepNumber: 5, title: 'Work History', icon: Icons.work_outline, onTap: () {}
                ),
                StepSquareCard(
                  stepNumber: 6, title: 'Gov Schemes', icon: Icons.gavel, onTap: () {}
                ),
                StepSquareCard(
                  stepNumber: 7, title: 'Insurance', icon: Icons.health_and_safety_outlined, onTap: () {}
                ),
                StepSquareCard(
                  stepNumber: 8, title: 'Tax Details', icon: Icons.receipt_long, onTap: () {}
                ),
                StepSquareCard(
                  stepNumber: 9, title: 'EMI & Loans', icon: Icons.credit_score, onTap: () {}
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Start Now',
              onPressed: () {
                context.push(AppRoutes.scoreStep(1));
              },
            ),
          ],
        ),
      ),
    );
  }
}
