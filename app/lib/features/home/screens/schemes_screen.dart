import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/cards/app_card.dart';

/// GigCredit Schemes Discovery Screen
/// Hero band → category tabs → 5 expandable scheme cards → helpline strip
class SchemesScreen extends StatefulWidget {
  const SchemesScreen({super.key});

  @override
  State<SchemesScreen> createState() => _SchemesScreenState();
}

class _SchemesScreenState extends State<SchemesScreen> {
  String _selectedCategory = 'All';
  int _expandedIndex = -1;

  static const _categories = ['All', 'Loans', 'Insurance', 'Pension', 'Registration'];

  static final _schemes = [
    const _SchemeData(
      title: 'PM SVANidhi',
      subtitle: 'Street Vendor Micro-Credit',
      description:
          'A special micro-credit facility scheme for providing affordable loans to street vendors to resume their livelihoods. Get up to ₹50,000 in 3 tiers.',
      category: 'Loans',
      url: 'https://www.pmsvanidhi.mohua.gov.in/',
      icon: Icons.storefront_rounded,
      accentColor: AppColors.schemeLoan,
      chipLabel: 'Micro-Credit',
      eligibility: '• Street vendors with valid ID\n• Must be in urban areas\n• Age 18+ years',
    ),
    const _SchemeData(
      title: 'PM Shram Yogi Maan-dhan',
      subtitle: 'Worker Pension Scheme',
      description:
          'A voluntary and contributory pension scheme for unorganized workers providing ₹3,000/month pension after age 60.',
      category: 'Pension',
      url: 'https://maandhan.in/',
      icon: Icons.account_balance_wallet_rounded,
      accentColor: AppColors.schemePension,
      chipLabel: 'Pension',
      eligibility: '• Monthly income < ₹15,000\n• Age 18-40 years\n• Not in EPFO/ESIC/NPS',
    ),
    const _SchemeData(
      title: 'PM Mudra Yojana',
      subtitle: 'Business Loans up to ₹10L',
      description:
          'Loans up to ₹10 lakhs for non-corporate, non-farm small/micro enterprises in 3 categories: Shishu (₹50K), Kishore (₹5L), Tarun (₹10L).',
      category: 'Loans',
      url: 'https://www.mudra.org.in/',
      icon: Icons.currency_rupee_rounded,
      accentColor: AppColors.schemeMudra,
      chipLabel: 'Business Loan',
      eligibility: '• Any Indian citizen\n• Non-farm income activity\n• No collateral required',
    ),
    const _SchemeData(
      title: 'PM Jeevan Jyoti Bima',
      subtitle: 'Life Insurance Cover',
      description:
          'One-year life insurance cover of ₹2,00,000 for death due to any reason. Annual premium of just ₹436.',
      category: 'Insurance',
      url: 'https://www.myscheme.gov.in/schemes/pmjjby',
      icon: Icons.health_and_safety_rounded,
      accentColor: AppColors.schemeInsurance,
      chipLabel: 'Insurance',
      eligibility: '• Age 18-50 years\n• Savings bank account\n• Aadhaar linked to bank',
    ),
    const _SchemeData(
      title: 'Udyam Registration',
      subtitle: 'MSME Certificate',
      description:
          'Free registration for MSMEs unlocking government benefits, subsidies, lower interest rates, and priority sector lending.',
      category: 'Registration',
      url: 'https://udyamregistration.gov.in/',
      icon: Icons.verified_rounded,
      accentColor: AppColors.schemeRegistration,
      chipLabel: 'Free Certificate',
      eligibility: '• Any micro/small/medium enterprise\n• Aadhaar + PAN required\n• Self-declaration based',
    ),
  ];

  List<_SchemeData> get _filteredSchemes {
    if (_selectedCategory == 'All') return _schemes;
    return _schemes.where((s) => s.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgScreen,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────
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
              'Government Schemes',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),

          // ── Hero Band ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              decoration: const BoxDecoration(gradient: AppColors.heroGradient),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🏛️  Financial Support',
                    style: AppTypography.eyebrow.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Government Schemes\nfor Gig Workers',
                    style: AppTypography.heroHeading.copyWith(fontSize: 26),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Explore verified schemes — micro-loans, pensions, and insurance designed for the informal sector.',
                    style: AppTypography.heroBody,
                  ),
                  const SizedBox(height: 20),
                  // Stats
                  const Row(
                    children: [
                      _MiniStat(value: '5', label: 'Schemes'),
                      SizedBox(width: 20),
                      _MiniStat(value: '₹10L', label: 'Max Loan'),
                      SizedBox(width: 20),
                      _MiniStat(value: '0%', label: 'Registration'),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),
          ),

          // ── Category Tabs ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final cat = _categories[i];
                    final isActive = cat == _selectedCategory;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedCategory = cat;
                        _expandedIndex = -1;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.greenPrimary
                              : AppColors.bgCard,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isActive
                                ? AppColors.greenPrimary
                                : AppColors.borderCard,
                          ),
                        ),
                        child: Text(
                          cat,
                          style: AppTypography.chip.copyWith(
                            color: isActive ? Colors.white : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ).animate().fadeIn(delay: 100.ms),
          ),

          // ── Scheme Cards ─────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final scheme = _filteredSchemes[index];
                  final isExpanded = _expandedIndex == index;
                  return _SchemeCardWidget(
                    data: scheme,
                    isExpanded: isExpanded,
                    onTap: () => setState(() =>
                        _expandedIndex = isExpanded ? -1 : index),
                    delay: 150 + (index * 60),
                  );
                },
                childCount: _filteredSchemes.length,
              ),
            ),
          ),

          // ── Helpline Strip ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.greenMuted.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.greenBright.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_in_talk_rounded,
                      color: AppColors.greenPrimary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Need help applying?',
                          style: AppTypography.labelLarge.copyWith(
                            fontSize: 13,
                            color: AppColors.greenPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Call helpline: 1800-180-5757 (toll-free)',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 600.ms),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  const _MiniStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: AppTypography.labelLarge
                .copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
        Text(label, style: AppTypography.statLabel.copyWith(fontSize: 10)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════

class _SchemeData {
  final String title, subtitle, description, category, url, chipLabel, eligibility;
  final IconData icon;
  final Color accentColor;

  const _SchemeData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.category,
    required this.url,
    required this.icon,
    required this.accentColor,
    required this.chipLabel,
    required this.eligibility,
  });
}

class _SchemeCardWidget extends StatelessWidget {
  final _SchemeData data;
  final bool isExpanded;
  final VoidCallback onTap;
  final int delay;

  const _SchemeCardWidget({
    required this.data,
    required this.isExpanded,
    required this.onTap,
    required this.delay,
  });

  Future<void> _launchUrl() async {
    final uri = Uri.parse(data.url);
    if (!await launchUrl(uri)) {
      debugPrint('Could not launch ${data.url}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        accentTopColor: data.accentColor,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: data.accentColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(data.icon, color: data.accentColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  // Title + chip
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.title,
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: data.accentColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                data.chipLabel,
                                style: AppTypography.labelSmall.copyWith(
                                  color: data.accentColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Expand arrow
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 280),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textMuted),
                  ),
                ],
              ),
            ),

            // Expanded content
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(color: AppColors.borderCard),
                    const SizedBox(height: 10),
                    Text(data.description,
                        style: AppTypography.bodyMedium
                            .copyWith(height: 1.55)),
                    const SizedBox(height: 14),
                    Text('Eligibility',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        )),
                    const SizedBox(height: 6),
                    Text(data.eligibility,
                        style: AppTypography.bodySmall
                            .copyWith(height: 1.6)),
                    const SizedBox(height: 16),
                    // Apply button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _launchUrl,
                        icon: const Icon(Icons.open_in_new_rounded, size: 16),
                        label: const Text('Apply Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: data.accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
              sizeCurve: Curves.easeOutCubic,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideY(
          begin: 0.06,
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
