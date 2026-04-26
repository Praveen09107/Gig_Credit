import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/buttons/primary_button.dart';
import '../../../app/app_router.dart';

class InputGuidanceScreen extends StatelessWidget {
  const InputGuidanceScreen({super.key});

  static const List<_StepGuide> _steps = [
    _StepGuide(
      step: 1,
      title: 'Basic Profile',
      description: 'Personal and professional details — name, DOB, address, work type, income.',
      uploads: [],
    ),
    _StepGuide(
      step: 2,
      title: 'Identity & KYC',
      description: 'Enter Aadhaar & PAN numbers, then upload ID documents and a live selfie.',
      uploads: [
        _UploadGuide('Aadhaar Card (Front)', 'Clear photo showing name, DOB, gender, photo, and Aadhaar number.', 'https://youtu.be/UvEIVaBREsw'),
        _UploadGuide('Aadhaar Card (Back)', 'Photo showing full address, state, PIN code.', ''),
        _UploadGuide('PAN Card Photo', 'Clear photo showing PAN number, name, father name, DOB.', ''),
        _UploadGuide('Live Selfie', 'Camera-only capture — face matched against Aadhaar photo.', ''),
      ],
    ),
    _StepGuide(
      step: 3,
      title: 'Bank Verification',
      description: 'Primary bank details, statement upload. Optional: secondary bank and UPI.',
      uploads: [
        _UploadGuide('Bank Statement (Primary)', 'PDF format, minimum 6 months coverage. Auto-extracts transactions.', ''),
        _UploadGuide('Bank Statement (Secondary)', 'Optional — recommended for platform workers with gig income in separate account.', ''),
        _UploadGuide('UPI Statement', 'Optional — PDF export from PhonePe / Google Pay / Paytm.', ''),
      ],
    ),
    _StepGuide(
      step: 4,
      title: 'Utility Bills',
      description: 'Toggle any bills you have — Electricity, Water, Gas, Mobile, Internet, Rent.',
      uploads: [
        _UploadGuide('Electricity Bill', 'Consumer number + bill photo/PDF showing payment amount.', 'https://youtu.be/R4o0ANijOxs'),
        _UploadGuide('Water Bill', 'Account number + bill photo showing recent payment.', ''),
        _UploadGuide('Gas / LPG Bill', 'Consumer/BP number + bill scan.', ''),
        _UploadGuide('Mobile Bill', 'Postpaid bill PDF or app screenshot.', 'https://youtu.be/HZW8S9hKWmY'),
        _UploadGuide('Internet / Broadband Bill', 'Customer number + bill scan.', ''),
        _UploadGuide('Rent Receipt / Agreement', 'Monthly receipt or registered rent agreement.', ''),
      ],
    ),
    _StepGuide(
      step: 5,
      title: 'Work Proof',
      description: 'Dynamic by work type — vehicle docs for drivers, vendor IDs for sellers.',
      uploads: [
        _UploadGuide('RC Book', 'Vehicle registration certificate photo.', 'https://youtu.be/oukaLiYTSZ0'),
        _UploadGuide('Driving Licence', 'Front and back photos of your driving licence.', ''),
        _UploadGuide('Vehicle Insurance', 'Valid motor insurance certificate.', ''),
        _UploadGuide('Platform Earnings Screenshots', 'Up to 5 screenshots from Uber/Ola/Swiggy/Zomato app.', 'https://youtu.be/W4D1ionJoD4'),
        _UploadGuide('Payout Summary', 'Earnings ledger or payout summary screenshot/PDF.', ''),
      ],
    ),
    _StepGuide(
      step: 6,
      title: 'Government Schemes',
      description: 'Toggle schemes you are enrolled in — SVANidhi, eShram, PM-SYM, PMJJBY, Mudra, PPF, Udyam.',
      uploads: [
        _UploadGuide('PM SVANidhi Proof', 'Approval letter or beneficiary certificate.', 'https://youtu.be/P2PVvctq8j0'),
        _UploadGuide('eShram Card', 'Photo of eShram card showing UAN.', ''),
        _UploadGuide('PM-SYM Pension Card', 'Pension account card or acknowledgement.', ''),
        _UploadGuide('PMJJBY Certificate', 'Certificate of Insurance (COI).', 'https://youtu.be/ZVVp9JD0-2g'),
        _UploadGuide('Mudra Loan Proof', 'Sanction letter or loan account statement.', ''),
        _UploadGuide('PPF Passbook', 'PPF passbook identity page or statement.', ''),
        _UploadGuide('Udyam / MSME Certificate', 'Udyam registration certificate.', ''),
      ],
    ),
    _StepGuide(
      step: 7,
      title: 'Insurance Coverage',
      description: 'Health, Vehicle, and Life insurance policies — policy numbers and documents.',
      uploads: [
        _UploadGuide('Health Policy Document', 'Policy schedule or e-policy PDF.', 'https://youtu.be/V9V2JdHdRlU'),
        _UploadGuide('Vehicle Insurance Document', 'Motor insurance certificate — required if you own a vehicle.', ''),
        _UploadGuide('Life Policy Document', 'Policy bond scan or premium certificate PDF.', 'https://youtu.be/xZJ5ahda03c'),
      ],
    ),
    _StepGuide(
      step: 8,
      title: 'ITR & GST Records',
      description: 'Income Tax Return and GST filings — PAN, assessment year, annual income.',
      uploads: [
        _UploadGuide('ITR Acknowledgement', 'ITR-V or e-Acknowledgement PDF.', 'https://youtu.be/ZPNxTjPB3Yw'),
        _UploadGuide('Form 26AS', 'Optional — tax credit statement linked to PAN.', ''),
        _UploadGuide('GST Document', 'GSTR-3B returns or GST Registration Certificate.', ''),
      ],
    ),
    _StepGuide(
      step: 9,
      title: 'EMI & Loan Behaviour',
      description: 'Active loans and EMIs — lender, amount, debit dates. Up to 5 entries.',
      uploads: [
        _UploadGuide('No uploads required', 'This step collects text-based loan details only. Lender name, EMI amount, and debit dates.', 'https://youtu.be/7_CmBxWUA5Y'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Input Guidance'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: _steps.length,
        itemBuilder: (context, index) {
          return _StepGuidanceCard(guide: _steps[index]);
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, -4)),
            ],
          ),
          child: PrimaryButton(
            label: 'Start Verification →',
            onPressed: () => context.go(AppRoutes.score),
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _expanded ? AppColors.accent.withValues(alpha: 0.5) : AppColors.surfaceVariant,
          width: _expanded ? 1.5 : 1,
        ),
        boxShadow: _expanded
            ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.08), blurRadius: 16, spreadRadius: 2)]
            : [],
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accentLight]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(child: Text('${g.step}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(g.title, style: AppTypography.titleMedium),
                        const SizedBox(height: 3),
                        Text(g.description, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),

          // Upload items
          if (_expanded && g.uploads.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Text(
                    g.uploads.length == 1 && g.uploads[0].title.startsWith('No') ? 'Info' : 'Required Documents',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textTertiary, letterSpacing: 0.8),
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
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () => setState(() => _showDetail = !_showDetail),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _showDetail ? AppColors.surfaceVariant.withValues(alpha: 0.5) : Colors.transparent,
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
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(u.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  Icon(
                    _showDetail ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
              if (_showDetail) ...[
                const SizedBox(height: 8),
                Text(u.description, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                if (u.youtubeUrl.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _launchUrl(u.youtubeUrl),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_circle_fill_rounded, color: Colors.red, size: 18),
                          SizedBox(width: 6),
                          Text('Watch Guide on YouTube', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
                        ],
                      ),
                    ),
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

  const _StepGuide({
    required this.step,
    required this.title,
    required this.description,
    required this.uploads,
  });
}

class _UploadGuide {
  final String title;
  final String description;
  final String youtubeUrl;

  const _UploadGuide(this.title, this.description, this.youtubeUrl);
}
