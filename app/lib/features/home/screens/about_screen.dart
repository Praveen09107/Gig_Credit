import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/cards/app_card.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About GigCredit'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Header Logo/Icon
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shield_rounded, size: 64, color: AppColors.accent),
            ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
          ),
          const SizedBox(height: 24),
          Text(
            'Redefining Trust for the Gig Economy',
            style: AppTypography.displayMedium,
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 16),
          Text(
            'GigCredit is an innovative, privacy-first, on-device credit scoring engine built specifically for autonomous gig workers, freelancers, and street vendors who lack traditional financial histories.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.6),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms),
          
          const SizedBox(height: 48),
          
          Text('Our Core Philosophy', style: AppTypography.titleLarge).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 16),
          _buildFeatureRow(Icons.lock_rounded, '100% Privacy', 'Your data never leaves your device. We use advanced on-device ML models to compute scores locally.', 500),
          _buildFeatureRow(Icons.auto_graph_rounded, 'Alternative Data', 'We look beyond CIBIL scores. We evaluate utility payments, government schemes, and work history.', 600),
          _buildFeatureRow(Icons.lightbulb_rounded, 'Explainable AI', 'We provide SHAP-based explanations so you know exactly why you got your score and how to improve it.', 700),
          
          const SizedBox(height: 48),
          
          Text('How It Works (The Flow)', style: AppTypography.titleLarge).animate().fadeIn(delay: 800.ms),
          const SizedBox(height: 24),
          
          // Flow Diagram
          _buildFlowStep('1', 'Data Collection', 'Upload Aadhaar, PAN, Bank Statements, and Work Proofs directly on your phone.', 900),
          _buildFlowConnector(1000),
          _buildFlowStep('2', 'On-Device Verification', 'Our Edge AI extracts and validates your documents instantly without cloud servers.', 1100),
          _buildFlowConnector(1200),
          _buildFlowStep('3', '7-Pillar Scoring Engine', 'An XGBoost Meta-Learner evaluates income, debts, savings, and compliance.', 1300),
          _buildFlowConnector(1400),
          _buildFlowStep('4', 'Credit Report & Offers', 'Instantly receive your Grade and tailored micro-loan offers from partner lenders.', 1500),
          
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String description, int delayMs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.accent, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleMedium),
                const SizedBox(height: 4),
                Text(description, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    ).animate().slideX(begin: 0.2, end: 0).fadeIn(delay: Duration(milliseconds: delayMs));
  }

  Widget _buildFlowStep(String number, String title, String description, int delayMs) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            radius: 20,
            child: Text(number, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleMedium),
                const SizedBox(height: 4),
                Text(description, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    ).animate().scale(delay: Duration(milliseconds: delayMs), duration: 400.ms, curve: Curves.easeOutBack);
  }

  Widget _buildFlowConnector(int delayMs) {
    return Center(
      child: Container(
        height: 24,
        width: 2,
        color: AppColors.accent.withValues(alpha: 0.5),
        margin: const EdgeInsets.symmetric(vertical: 4),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delayMs));
  }
}
