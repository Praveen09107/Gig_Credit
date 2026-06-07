import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/buttons/primary_button.dart';
import '../../../app/app_router.dart';

/// GigCredit Input Guidance Screen
/// Accordion cards showing upload requirements per step
class InputGuidanceScreen extends StatelessWidget {
  const InputGuidanceScreen({super.key});

  static const List<_StepGuide> _steps = [
    _StepGuide(step: 1, title: 'Basic Profile',
      description: 'Personal and professional details — name, DOB, address, work type, income.',
      uploads: [
        _UploadGuide('No uploads required', 'This step collects text-based details only:\n• Full Name & Date of Birth\n• Gender & Address\n• Gig Platform & Work Type\n• Monthly Income Estimate', ''),
      ]),
    _StepGuide(step: 2, title: 'Identity & KYC',
      description: 'Enter Aadhaar & PAN numbers, then upload ID documents and a live selfie.',
      uploads: [
        _UploadGuide('Aadhaar Card (Front)', 'Clear photo showing name, DOB, gender, photo, and Aadhaar number.', 'https://youtu.be/kFjpAR61hfs?si=vGFqPqrjJpYy4so6'),
        _UploadGuide('Aadhaar Card (Back)', 'Photo showing full address, state, PIN code.', 'https://youtu.be/kFjpAR61hfs?si=vGFqPqrjJpYy4so6'),
        _UploadGuide('PAN Card Photo', 'Clear photo showing PAN number, name, father name, DOB.', 'https://youtu.be/NT4V93Wca7Q?si=45iCbnSSmdC8_Gb1'),
        _UploadGuide('Live Selfie', 'Camera-only capture — face matched against Aadhaar photo.', ''),
      ]),
    _StepGuide(step: 3, title: 'Bank Verification',
      description: 'Primary bank details, statement upload. Optional: secondary bank and UPI.',
      uploads: [
        _UploadGuide('Bank Statement (Primary)', 'PDF format, minimum 6 months coverage. Auto-extracts transactions.', ''),
        _UploadGuide('Bank Statement (Secondary)', 'Optional — recommended for platform workers with gig income in separate account.', ''),
        _UploadGuide('UPI Statement', 'Optional — PDF export from PhonePe / Google Pay / Paytm.', ''),
      ]),
    _StepGuide(step: 4, title: 'Utility Bills & Subscriptions',
      description: 'Toggle any bills you have — Electricity, Gas, Mobile, Internet, Rent, or OTT.',
      uploads: [
        _UploadGuide('Electricity Bill', 'Consumer number + bill photo/PDF showing payment amount.', 'https://youtu.be/R4o0ANijOxs?si=zGunB63b3HBdwqM_'),
        _UploadGuide('OTT Subscription Receipts', 'Screenshot or PDF of recent OTT platform subscription payment.', ''),
        _UploadGuide('Gas / LPG Bill', 'Consumer/BP number + bill scan.', 'https://youtu.be/HZW8S9hKWmY?si=YgCV_gIHt6KGjpaZ'),
        _UploadGuide('Mobile Bill - Airtel Prepaid', 'Screenshot of successful recharge from Airtel Thanks app.', 'https://youtu.be/fY-tQ4-3HzY?si=zmuWnVRP34nnfXkP'),
        _UploadGuide('Mobile Bill - Airtel Postpaid', 'Airtel Postpaid bill PDF.', 'https://youtu.be/Mcb6_6Da1KQ?si=1xRWxpOrG8nfUNqc'),
        _UploadGuide('Mobile Bill - Jio Prepaid', 'Screenshot of recharge from MyJio app.', 'https://youtube.com/shorts/VJikXjEFovI?si=9KiBA3qhWa_mWCMj'),
        _UploadGuide('Mobile Bill - Jio Postpaid', 'Jio Postpaid bill PDF.', 'https://youtu.be/CP0xqg6iv0g?si=efBtU_iEWt9z0PSV'),
        _UploadGuide('Internet / Broadband Bill', 'Customer number + bill scan.', ''),
        _UploadGuide('Rent Receipt / Agreement', 'Monthly receipt or registered rent agreement.', ''),
      ]),
    _StepGuide(step: 5, title: 'Work Proof',
      description: 'Documents based on your specific GigCredit profession category.',
      uploads: [
        _UploadGuide('Platform Worker: Earnings / Payouts', 'Screenshots of recent earnings from Uber/Ola/Swiggy/Zomato app or payout PDFs.', ''),
        _UploadGuide('Platform Worker: Vehicle Docs', 'RC Book, Driving Licence, or Motor Insurance (if you are a driver partner).', ''),
        _UploadGuide('Street Vendor: Market/Stall Receipts', 'Receipts for daily/monthly local market fees or vendor association IDs.', ''),
        _UploadGuide('Skilled Trader: Work Contracts', 'Job cards, WhatsApp agreements, or receipts for tools and materials.', ''),
        _UploadGuide('Freelancer: Invoices & Payouts', 'Copies of client invoices or payment gateway (PayPal/Razorpay) payout receipts.', ''),
      ]),
    _StepGuide(step: 6, title: 'Government Schemes',
      description: 'Toggle schemes you are enrolled in — SVANidhi, eShram, PM-SYM, PMJJBY, Mudra, PPF, Udyam.',
      uploads: [
        _UploadGuide('PM SVANidhi Proof', 'Approval letter or beneficiary certificate.', 'https://youtu.be/U3dpJEXNGqk?si=LoL1nOhadllwSbhj', 'https://www.pmsvanidhi.mohua.gov.in/'),
        _UploadGuide('eShram Card', 'Photo of eShram card showing UAN.', 'https://youtu.be/ENNlmt4wnJU?si=BWSnztKY8EFZQW8J', 'https://eshram.gov.in/indexmain'),
        _UploadGuide('PM-SYM Pension Card', 'Pension account card or acknowledgement.', 'https://youtu.be/9l0gllO1Tgo?si=Ii43QPZ6MEUezx8H', 'https://maandhan.in/'),
        _UploadGuide('PMJJBY Certificate', 'Certificate of Insurance (COI).', 'https://youtu.be/dj7yHy-gAxk?si=vw4ODkzQjY1zrY1d', 'https://www.myscheme.gov.in/schemes/pmjjby'),
        _UploadGuide('Mudra Loan Proof', 'Sanction letter or loan account statement.', 'https://youtu.be/Ln0bDUvf_-A?si=AH0BbrLiAfe_scpa', 'https://www.hdfc.bank.in/pm-mudra-yojana/documentation'),
        _UploadGuide('PPF Passbook', 'PPF passbook identity page or statement.', 'https://youtu.be/j1mckuo3aFc?si=5T_ORTL2rWEjlCMK', 'https://passbook.epfindia.gov.in/MemberPassBook/login'),
        _UploadGuide('Udyam / MSME Certificate', 'Udyam registration certificate.', 'https://youtu.be/eT6P_6-hBps?si=5retiGx0ddM5Dj2c', 'https://udyamregistration.gov.in/'),
      ]),
    _StepGuide(step: 7, title: 'Insurance Coverage',
      description: 'Health, Vehicle, and Life insurance policies — policy numbers and documents.',
      uploads: [
        _UploadGuide('Health Policy Document', 'Policy schedule or e-policy PDF.', 'https://youtu.be/V9V2JdHdRlU'),
        _UploadGuide('Vehicle Insurance Document', 'Motor insurance certificate — required if you own a vehicle.', 'https://youtu.be/eIgj9weLoWg?si=dtlkeeIWPeq-QRDi'),
        _UploadGuide('Life Policy Document', 'Policy bond scan or premium certificate PDF.', 'https://youtu.be/xZJ5ahda03c'),
      ]),
    _StepGuide(step: 8, title: 'ITR & GST Records',
      description: 'Income Tax Return and GST filings — PAN, assessment year, annual income.',
      uploads: [
        _UploadGuide('ITR Acknowledgement', 'ITR-V or e-Acknowledgement PDF.', 'https://youtu.be/ZPNxTjPB3Yw', 'https://eportal.incometax.gov.in/'),
        _UploadGuide('Form 26AS', 'Optional — tax credit statement linked to PAN.', '', 'https://eportal.incometax.gov.in/'),
        _UploadGuide('GST Document', 'GSTR-3B returns or GST Registration Certificate.', 'https://youtu.be/G5gPUlNji6o?si=Sz8cpbb1O6vshqdR', 'https://www.gst.gov.in/'),
      ]),
    _StepGuide(step: 9, title: 'EMI & Loan Behaviour',
      description: 'Active loans and EMIs — lender, amount, debit dates. Up to 5 entries.',
      uploads: [
        _UploadGuide('No uploads required', 'This step collects text-based loan details only. Lender name, EMI amount, and debit dates.', 'https://youtu.be/7_CmBxWUA5Y'),
      ]),
  ];

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
            title: Text('Input Guidance',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
            centerTitle: true,
          ),

          // Hero
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF003820), // AppColors.greenDark
                    Color(0xFF00663A), // AppColors.greenPrimary
                  ],
                )
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Icon(Icons.description_outlined, size: 140, color: Colors.white.withValues(alpha: 0.1))
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .moveY(begin: -10, end: 10, duration: 3.seconds, curve: Curves.easeInOutSine),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: const Text('📋  9-Step Verification Guide',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),
                      const SizedBox(height: 16),
                      Text('What You\'ll Need',
                          style: AppTypography.heroHeading.copyWith(fontSize: 28, color: Colors.white)).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
                      const SizedBox(height: 8),
                      Text('Tap each step to discover the required documents and insights needed to build your credit profile.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14, height: 1.5))
                          .animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Steps
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _StepGuidanceCard(guide: _steps[i]),
                childCount: _steps.length,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            border: const Border(top: BorderSide(color: AppColors.borderCard)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -4)),
            ],
          ),
          child: PrimaryButton(
            label: 'START VERIFICATION',
            onPressed: () => context.go(AppRoutes.score),
            suffixIcon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}

class _StepGuidanceCard extends StatefulWidget {
  final _StepGuide guide;
  const _StepGuidanceCard({required this.guide});

  @override
  State<_StepGuidanceCard> createState() => _StepGuidanceCardState();
}

class _StepGuidanceCardState extends State<_StepGuidanceCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final g = widget.guide;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _expanded ? AppColors.greenBright.withValues(alpha: 0.4) : AppColors.borderCard,
          width: _expanded ? 1.5 : 1,
        ),
        boxShadow: _expanded
            ? [BoxShadow(color: AppColors.greenBright.withValues(alpha: 0.08), blurRadius: 16, spreadRadius: 2)]
            : AppColors.cardShadow,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: AppColors.ctaGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text('${g.step}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(g.title, style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Text(g.description,
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),

          if (_expanded && g.uploads.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1, color: AppColors.borderCard),
                  const SizedBox(height: 12),
                  Text(
                    g.uploads.length == 1 && g.uploads[0].title.startsWith('No') ? 'INFO' : 'REQUIRED DOCUMENTS',
                    style: AppTypography.sectionLabel,
                  ),
                  const SizedBox(height: 8),
                  ...g.uploads.map((u) => _UploadItemTile(upload: u)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _UploadItemTile extends StatefulWidget {
  final _UploadGuide upload;
  const _UploadItemTile({required this.upload});

  @override
  State<_UploadItemTile> createState() => _UploadItemTileState();
}

class _UploadItemTileState extends State<_UploadItemTile> {
  bool _showDetail = false;

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.upload;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () => setState(() => _showDetail = !_showDetail),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _showDetail ? AppColors.greenMuted.withValues(alpha: 0.5) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _showDetail ? Icons.description : Icons.upload_file_rounded,
                    size: 18,
                    color: AppColors.greenPrimary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(u.title,
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        )),
                  ),
                  Icon(
                    _showDetail ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
              if (_showDetail) ...[
                const SizedBox(height: 8),
                Text(u.description,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.4)),
                if (u.youtubeUrl.isNotEmpty || u.applyUrl.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (u.youtubeUrl.isNotEmpty)
                        InkWell(
                          onTap: () => _launchUrl(u.youtubeUrl),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.play_circle_fill_rounded, color: Colors.red, size: 16),
                                SizedBox(width: 6),
                                Text('Watch Guide',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red)),
                              ],
                            ),
                          ),
                        ).animate().scale(delay: 100.ms, duration: 200.ms, curve: Curves.easeOutBack),
                      if (u.applyUrl.isNotEmpty)
                        InkWell(
                          onTap: () => _launchUrl(u.applyUrl),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.greenPrimary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.open_in_new_rounded, color: AppColors.greenPrimary, size: 16),
                                SizedBox(width: 6),
                                Text('Apply Now',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.greenPrimary)),
                              ],
                            ),
                          ),
                        ).animate().scale(delay: 200.ms, duration: 200.ms, curve: Curves.easeOutBack),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StepGuide {
  final int step;
  final String title;
  final String description;
  final List<_UploadGuide> uploads;
  const _StepGuide({required this.step, required this.title, required this.description, required this.uploads});
}

class _UploadGuide {
  final String title;
  final String description;
  final String youtubeUrl;
  final String applyUrl;
  const _UploadGuide(this.title, this.description, this.youtubeUrl, [this.applyUrl = '']);
}
