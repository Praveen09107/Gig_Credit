import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import 'dart:math' as math;

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FFF8),
      body: CustomScrollView(
        slivers: [
          // SECTION 0 — TOP HEADER BAR
          SliverAppBar(
            pinned: true,
            backgroundColor: const Color(0xFF00522F),
            elevation: 4,
            shadowColor: Colors.black45,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'About GigCredit',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.person_outline_rounded,
                    color: Colors.white),
                onPressed: () {},
              )
            ],
          ),
          SliverToBoxAdapter(child: const _TargetUsersSection()),
          SliverToBoxAdapter(child: const SizedBox(height: 32)),
          
          SliverToBoxAdapter(child: const _PipelineSection()),
          SliverToBoxAdapter(child: const SizedBox(height: 32)),

          SliverToBoxAdapter(child: const _NovelInputsSection()),
          SliverToBoxAdapter(child: const SizedBox(height: 32)),

          SliverToBoxAdapter(child: const _TrustEngineSection()),
          SliverToBoxAdapter(child: const SizedBox(height: 32)),

          SliverToBoxAdapter(child: const _EightPillarsSection()),
          SliverToBoxAdapter(child: const SizedBox(height: 48)),

          SliverToBoxAdapter(
            child: Center(
              child: const Text(
                'GigCredit: Privacy-first, on-device credit scores for India\'s real workers.',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 11),
              ).animate().fadeIn(delay: 200.ms),
            ),
          ),
          SliverToBoxAdapter(child: const SizedBox(height: 24)),
        ],
      ),
    );
  }
}

// ──────────────────────────────── SECTION 1 — TARGET USERS
class _TargetUsersSection extends StatefulWidget {
  const _TargetUsersSection();

  @override
  State<_TargetUsersSection> createState() => _TargetUsersSectionState();
}

class _TargetUsersSectionState extends State<_TargetUsersSection> {
  final PageController _pageCtrl = PageController(viewportFraction: 0.85);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00522F), Color(0xFF008A43)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Credit Designed For\nReal-World Workers',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.2),
                ).animate().slideY(begin: 0.2).fadeIn(),
                const SizedBox(height: 8),
                Text(
                  'Platform workers, street vendors, skilled trades, and freelancers who banks struggle to read correctly.',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      height: 1.4),
                ).animate().slideY(begin: 0.2).fadeIn(delay: 100.ms),
              ],
            ),
          ),
          SizedBox(
            height: 235,
            child: PageView(
              controller: _pageCtrl,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildPersonaCard(
                  'Platform Worker',
                  Icons.moped_rounded,
                  [
                    'Income via UPI, cash, & multiple apps.',
                    'Current systems reject "irregular income".'
                  ],
                  ['No CIBIL', 'Multiple platforms'],
                ),
                _buildPersonaCard(
                  'Street Vendor',
                  Icons.storefront_rounded,
                  [
                    'Daily cash sales & local market fees.',
                    'Seasonal dips misread as permanent risk.'
                  ],
                  ['Cash-heavy', 'Seasonal work'],
                ),
                _buildPersonaCard(
                  'Skilled Trade',
                  Icons.handyman_rounded,
                  [
                    'Jobs via calls/WhatsApp, paid in cash.',
                    'Short gaps treated as unemployment.'
                  ],
                  ['No formal slip', 'Contract gaps'],
                ),
                _buildPersonaCard(
                  'Freelancer',
                  Icons.laptop_mac_rounded,
                  [
                    'Project-based payouts & international.',
                    'No standard proof of salary.'
                  ],
                  ['Irregular invoices', 'Scattered income'],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPersonaCard(
      String title, IconData icon, List<String> findings, List<String> chips) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5FFF8),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00B36F).withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFE9F8EE),
                  child: Icon(icon, color: const Color(0xFF006837), size: 20),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF006837)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Target User',
                      style: TextStyle(
                          color: Color(0xFF006837),
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...findings.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline,
                          size: 14, color: Color(0xFF047857)),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(f,
                              style: const TextStyle(
                                  color: Color(0xFF4B5563),
                                  fontSize: 12,
                                  height: 1.3))),
                    ],
                  ),
                )),
            const Spacer(),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: chips
                  .map((c) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9F8EE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(c,
                            style: const TextStyle(
                                color: Color(0xFF047857),
                                fontSize: 10,
                                fontWeight: FontWeight.w600)),
                      ))
                  .toList(),
            )
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1);
  }
}

// ──────────────────────────────── SECTION 2 — PIPELINE
class _PipelineSection extends StatefulWidget {
  const _PipelineSection();

  @override
  State<_PipelineSection> createState() => _PipelineSectionState();
}

class _PipelineSectionState extends State<_PipelineSection> {
  int _activeStep = 0;

  final List<Map<String, dynamic>> _steps = [
    {
      'icon': Icons.memory_rounded,
      'title': 'On-Device Processing',
      'sub': 'OCR, feature engineering',
      'body':
          'We parse PDFs, screenshots, and proofs locally. 115+ behavioral features computed on the phone.'
    },
    {
      'icon': Icons.speed_rounded,
      'title': 'Explainable Score Engine',
      'sub': '8 pillars + SHAP',
      'body':
          'Each pillar model rates one dimension. Tree-based SHAP reveals what helped or hurt your score.'
    },
    {
      'icon': Icons.security_rounded,
      'title': 'Privacy Guard',
      'sub': 'Raw data auto-delete',
      'body':
          'Once scored, raw PDFs and texts are deleted. Only an encrypted report remains.'
    },
    {
      'icon': Icons.assignment_turned_in_rounded,
      'title': 'Score Report & Actions',
      'sub': 'Multi-language XAI',
      'body':
          'You get a 300-900 score, 8 pillar bars, and personalized steps to improve in your language.'
    },
    {
      'icon': Icons.account_balance_rounded,
      'title': 'Loan & Schemes',
      'sub': 'Eligibility & tracking',
      'body':
          'Our affordability engine checks EMI-to-income before showing any real loan offers.'
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('What Actually Runs Inside GigCredit',
              style: TextStyle(
                  color: Color(0xFF00522F),
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text(
              'From bank statement to explainable score and safe loan offer — all with on-device processing.',
              style: TextStyle(color: Color(0xFF4B5563), fontSize: 13)),
          const SizedBox(height: 24),
          Column(
            children: List.generate(_steps.length, (index) {
              final step = _steps[index];
              final isActive = _activeStep == index;
              return GestureDetector(
                onTap: () => setState(() => _activeStep = index),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFF00B36F)
                                : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: isActive
                                    ? const Color(0xFF00B36F)
                                    : const Color(0xFFE5E7EB),
                                width: 2),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                        color: const Color(0xFF00B36F)
                                            .withOpacity(0.4),
                                        blurRadius: 8)
                                  ]
                                : [],
                          ),
                          child: Icon(step['icon'],
                              size: 16,
                              color: isActive
                                  ? Colors.white
                                  : const Color(0xFF9CA3AF)),
                        ),
                        if (index != _steps.length - 1)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 2,
                            height: isActive ? 90 : 50,
                            color: isActive
                                ? const Color(0xFF00B36F)
                                : const Color(0xFFE5E7EB),
                          )
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(step['title'],
                              style: TextStyle(
                                  color: isActive
                                      ? const Color(0xFF111827)
                                      : const Color(0xFF6B7280),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                          Text(step['sub'],
                              style: const TextStyle(
                                  color: Color(0xFF047857), fontSize: 11)),
                          AnimatedCrossFade(
                            firstChild: const SizedBox(
                                height: 16, width: double.infinity),
                            secondChild: Container(
                              margin: const EdgeInsets.only(top: 8, bottom: 20),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: const Color(0xFFE9F8EE)),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4))
                                ],
                              ),
                              child: Text(step['body'],
                                  style: const TextStyle(
                                      color: Color(0xFF4B5563),
                                      fontSize: 13,
                                      height: 1.4)),
                            ),
                            crossFadeState: isActive
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 250),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              );
            }),
          )
        ],
      ),
    );
  }
}

// ──────────────────────────────── SECTION 3 — NOVEL INPUTS
class _NovelInputsSection extends StatelessWidget {
  const _NovelInputsSection();

  @override
  Widget build(BuildContext context) {
    final inputs = [
      {
        'title': 'Govt Schemes',
        'icon': Icons.account_balance_rounded,
        'desc': 'e-Shram, Mudra loans prove someone trusts your business.',
        'pill': 'P1, P7'
      },
      {
        'title': 'Utility Bills',
        'icon': Icons.receipt_long_rounded,
        'desc': 'Consistent payments highlight everyday discipline.',
        'pill': 'P2, P4'
      },
      {
        'title': 'Platform Earnings',
        'icon': Icons.monetization_on_rounded,
        'desc': 'Screenshots reveal actual monthly earning power.',
        'pill': 'P1, P5'
      },
      {
        'title': 'Market Fees',
        'icon': Icons.storefront_rounded,
        'desc': 'Local receipts show your stall is active & stable.',
        'pill': 'P1, P3'
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('What We Look At',
              style: TextStyle(
                  color: Color(0xFF00522F),
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Signals that actually describe your repayment ability.',
              style: TextStyle(color: Color(0xFF4B5563), fontSize: 13)),
          const SizedBox(height: 16),
          GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.95,
            ),
            itemCount: inputs.length,
            itemBuilder: (ctx, i) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                          color: Color(0xFFE9F8EE), shape: BoxShape.circle),
                      child: Icon(inputs[i]['icon'] as IconData,
                          color: const Color(0xFF006837), size: 18),
                    ),
                    const Spacer(),
                    Text(inputs[i]['title'] as String,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(inputs[i]['desc'] as String,
                        style: const TextStyle(
                            color: Color(0xFF4B5563),
                            fontSize: 11,
                            height: 1.2),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: const Color(0xFFE9F8EE),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(inputs[i]['pill'] as String,
                          style: const TextStyle(
                              color: Color(0xFF047857),
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: 100 * i))
                  .scale();
            },
          )
        ],
      ),
    );
  }
}

// ──────────────────────────────── SECTION 4 — TRUST ENGINE
class _TrustEngineSection extends StatelessWidget {
  const _TrustEngineSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How We Trust Your Data',
              style: TextStyle(
                  color: Color(0xFF00522F),
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text(
              'Verification checks "Is this real?". Validation checks "Does it make sense?".',
              style: TextStyle(color: Color(0xFF4B5563), fontSize: 13)),
          const SizedBox(height: 16),

          // Card A: Verification
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: const Border(
                  left: BorderSide(color: Color(0xFF00B36F), width: 4)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Verification (External APIs)',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 8),
                _buildBullet('Check Aadhaar against UIDAI.'),
                _buildBullet('Verify PAN/ITR with tax servers.'),
                _buildBullet('Confirm IFSC via banking APIs.'),
                const SizedBox(height: 8),
                const Text('Runs against official services only.',
                    style: TextStyle(color: Color(0xFF047857), fontSize: 11)),
              ],
            ),
          ).animate().slideX(begin: -0.1),

          const SizedBox(height: 12),

          // Card B: Validation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: const Border(
                  left: BorderSide(color: Color(0xFF00522F), width: 4)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Validation (On-Device Logic)',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 8),
                _buildBullet('Cross-ID: Aadhaar name = PAN name.'),
                _buildBullet('Logic: Income claimed ≤ Bank deposits.'),
                _buildBullet('State: No impossible dates or balances.'),
              ],
            ),
          ).animate().slideX(begin: 0.1),

          const SizedBox(height: 12),

          // Outcome Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF00522F), Color(0xFF006837)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user_rounded,
                    color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Trusted Profile Created',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      SizedBox(height: 4),
                      Text(
                          'Only verified & validated data flows into the scoring engine.',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                )
              ],
            ),
          ).animate().scale(delay: 200.ms)
        ],
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.circle, size: 6, color: Color(0xFF00B36F)),
          ),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style:
                      const TextStyle(color: Color(0xFF4B5563), fontSize: 12))),
        ],
      ),
    );
  }
}

// ──────────────────────────────── SECTION 5 — EIGHT PILLARS
class _EightPillarsSection extends StatefulWidget {
  const _EightPillarsSection();

  @override
  State<_EightPillarsSection> createState() => _EightPillarsSectionState();
}

class _EightPillarsSectionState extends State<_EightPillarsSection> {
  int? _expandedIdx;

  final pillars = [
    {
      'code': 'P1',
      'name': 'Income Stability',
      'desc': 'Predictability of monthly earnings.',
      'inputs': 'Bank, Platform'
    },
    {
      'code': 'P2',
      'name': 'Payment Discipline',
      'desc': 'Reliability of paying bills on time.',
      'inputs': 'Utility, Rent'
    },
    {
      'code': 'P3',
      'name': 'Debt Management',
      'desc': 'EMI burden compared to income.',
      'inputs': 'Loans, EMI'
    },
    {
      'code': 'P4',
      'name': 'Savings Behaviour',
      'desc': 'Financial buffer for bad months.',
      'inputs': 'Bank Balance'
    },
    {
      'code': 'P5',
      'name': 'Work & Identity',
      'desc': 'Authenticity of professional gig work.',
      'inputs': 'e-Shram, Apps'
    },
    {
      'code': 'P6',
      'name': 'Financial Resilience',
      'desc': 'Protection against life shocks.',
      'inputs': 'Insurance'
    },
    {
      'code': 'P7',
      'name': 'Social Accountability',
      'desc': 'Signals of community reliability.',
      'inputs': 'SHG, Schemes'
    },
    {
      'code': 'P8',
      'name': 'Tax & Compliance',
      'desc': 'Formal adherence to tax norms.',
      'inputs': 'ITR, PAN'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('One Score, Eight Pillars',
              style: TextStyle(
                  color: Color(0xFF00522F),
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text(
              'Each pillar is its own mini-model for exact explainability.',
              style: TextStyle(color: Color(0xFF4B5563), fontSize: 13)),
          const SizedBox(height: 24),
          Center(
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFF00B36F).withOpacity(0.3), width: 8),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                        _expandedIdx != null
                            ? pillars[_expandedIdx!]['code']!
                            : '8',
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF00522F))),
                    Text(_expandedIdx != null ? 'Pillar' : 'Pillars',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF047857))),
                  ],
                ),
              ),
            )
                .animate(target: _expandedIdx != null ? 1 : 0)
                .scaleXY(end: 1.05, duration: 200.ms),
          ),
          const SizedBox(height: 24),
          Column(
            children: List.generate(pillars.length, (i) {
              final isExp = _expandedIdx == i;
              return GestureDetector(
                onTap: () => setState(() => _expandedIdx = isExp ? null : i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: isExp ? const Color(0xFFE9F8EE) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: isExp
                              ? const Color(0xFF00B36F)
                              : Colors.transparent),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8)
                      ]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('${pillars[i]['code']} · ${pillars[i]['name']}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14)),
                          const Spacer(),
                          Icon(
                              isExp
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: const Color(0xFF006837),
                              size: 20)
                        ],
                      ),
                      if (isExp) ...[
                        const SizedBox(height: 8),
                        Text(pillars[i]['desc']!,
                            style: const TextStyle(
                                color: Color(0xFF4B5563), fontSize: 13)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Inputs: ',
                                style: TextStyle(
                                    color: Color(0xFF047857),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6)),
                              child: Text(pillars[i]['inputs']!,
                                  style: const TextStyle(
                                      fontSize: 10, color: Color(0xFF00522F))),
                            )
                          ],
                        )
                      ]
                    ],
                  ),
                ),
              );
            }),
          )
        ],
      ),
    );
  }
}
