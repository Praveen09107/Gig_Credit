import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../../shared/widgets/buttons/primary_button.dart';
import '../../../state/credit_provider.dart';

class BuyCreditsScreen extends ConsumerWidget {
  const BuyCreditsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final credits = ref.watch(creditProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('GigCredit Credits')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Current balance card
          AppCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text('Available Credits', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Text(
                  '${credits.totalAvailable}',
                  style: AppTypography.displayLarge.copyWith(color: AppColors.accent),
                ),
                const SizedBox(height: 4),
                const Text('credits', style: TextStyle(color: AppColors.textTertiary)),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Text('Buy Credit Packs', style: AppTypography.titleLarge),
          const SizedBox(height: 16),

          _CreditPackCard(
            credits: 1,
            price: '₹49',
            description: '1 full credit report generation',
            isPopular: false,
            onBuy: () => ref.read(creditProvider.notifier).addPaidCredits(1),
          ),
          const SizedBox(height: 12),
          _CreditPackCard(
            credits: 3,
            price: '₹129',
            description: '3 reports — save ₹18',
            isPopular: true,
            onBuy: () => ref.read(creditProvider.notifier).addPaidCredits(3),
          ),
          const SizedBox(height: 12),
          _CreditPackCard(
            credits: 10,
            price: '₹399',
            description: '10 reports — save ₹91',
            isPopular: false,
            onBuy: () => ref.read(creditProvider.notifier).addPaidCredits(10),
          ),

          const SizedBox(height: 32),
          Text('How Credits Work', style: AppTypography.titleMedium),
          const SizedBox(height: 12),
          const _InfoRow(icon: Icons.generating_tokens, text: 'Each credit report costs 1 credit to generate.'),
          const SizedBox(height: 8),
          const _InfoRow(icon: Icons.card_giftcard, text: 'New users get 1 free credit on signup.'),
          const SizedBox(height: 8),
          const _InfoRow(icon: Icons.refresh, text: 'Credits never expire once purchased.'),
        ],
      ),
    );
  }
}

class _CreditPackCard extends StatelessWidget {
  final int credits;
  final String price;
  final String description;
  final bool isPopular;
  final VoidCallback onBuy;

  const _CreditPackCard({
    required this.credits,
    required this.price,
    required this.description,
    required this.isPopular,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '$credits',
                style: AppTypography.titleLarge.copyWith(color: AppColors.accent),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('$credits Credit${credits > 1 ? 's' : ''}', style: AppTypography.titleMedium),
                    if (isPopular) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.gradeA.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('BEST VALUE', style: TextStyle(color: AppColors.gradeA, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          PrimaryButton(
            label: price,
            onPressed: onBuy,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.accentLight),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(color: AppColors.textSecondary))),
      ],
    );
  }
}
