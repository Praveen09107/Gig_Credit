import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/cards/app_card.dart';

class SchemesScreen extends StatelessWidget {
  const SchemesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Government Schemes'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Financial Support & Schemes',
            style: AppTypography.displaySmall,
          ).animate().fadeIn().slideX(begin: -0.1, end: 0),
          const SizedBox(height: 8),
          Text(
            'Explore government-verified micro-loans and insurance schemes designed specifically for unorganized sector and gig workers.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.5),
          ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),
          const SizedBox(height: 32),
          
          _SchemeCard(
            title: 'PM SVANidhi',
            description: 'A special micro-credit facility scheme for providing affordable loans to street vendors to resume their livelihoods.',
            url: 'https://www.pmsvanidhi.mohua.gov.in/',
            icon: Icons.storefront_rounded,
            delayMs: 200,
          ),
          _SchemeCard(
            title: 'PM Shram Yogi Maan-dhan (PM-SYM)',
            description: 'A voluntary and contributory pension scheme for unorganized workers for old age protection.',
            url: 'https://maandhan.in/',
            icon: Icons.account_balance_wallet_rounded,
            delayMs: 300,
          ),
          _SchemeCard(
            title: 'PM Mudra Yojana',
            description: 'A scheme providing loans up to 10 lakhs to non-corporate, non-farm small/micro enterprises.',
            url: 'https://www.hdfc.bank.in/pm-mudra-yojana/documentation',
            icon: Icons.currency_rupee_rounded,
            delayMs: 400,
          ),
          _SchemeCard(
            title: 'PM Jeevan Jyoti Bima Yojana (PMJJBY)',
            description: 'A one-year life insurance scheme renewable from year to year offering coverage for death due to any reason.',
            url: 'https://www.myscheme.gov.in/schemes/pmjjby',
            icon: Icons.health_and_safety_rounded,
            delayMs: 500,
          ),
          _SchemeCard(
            title: 'Udyam Registration Certificate',
            description: 'A general registration for MSMEs that unlocks a variety of government benefits, subsidies, and lower interest rates.',
            url: 'https://www.scsthub.in/content/udyam-registration-portal',
            icon: Icons.verified_rounded,
            delayMs: 600,
          ),
        ],
      ),
    );
  }
}

class _SchemeCard extends StatelessWidget {
  final String title;
  final String description;
  final String url;
  final IconData icon;
  final int delayMs;

  const _SchemeCard({
    required this.title,
    required this.description,
    required this.url,
    required this.icon,
    required this.delayMs,
  });

  Future<void> _launchUrl() async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: _launchUrl,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.accent, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTypography.titleLarge),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            'Apply Now',
                            style: AppTypography.labelLarge.copyWith(color: AppColors.accent),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded, color: AppColors.accent, size: 16),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ).animate().slideY(begin: 0.2, end: 0).fadeIn(delay: Duration(milliseconds: delayMs)),
    );
  }
}
