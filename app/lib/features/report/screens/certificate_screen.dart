import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/buttons/secondary_button.dart';
import '../../../state/score_provider.dart';

/// GigCredit Official Certificate Screen
/// Formal green-themed certificate card with export capability
class CertificateScreen extends ConsumerStatefulWidget {
  const CertificateScreen({super.key});

  @override
  ConsumerState<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends ConsumerState<CertificateScreen> {
  final GlobalKey _repKey = GlobalKey();

  Future<void> _exportAsImage() async {
    try {
      final boundary = _repKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Certificate saved to gallery (Demo)',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
            backgroundColor: AppColors.bgCard,
          ),
        );
      }
    } catch (e) {
      // Ignored for demo
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = ref.watch(scoreProvider).reportData;

    if (report == null) {
      return Scaffold(
        backgroundColor: AppColors.bgScreen,
        body: Center(
          child: Text('No report data', style: AppTypography.bodyMedium),
        ),
      );
    }

    final gradeColor = AppColors.gradeColor(report.grade);

    return Scaffold(
      backgroundColor: AppColors.bgScreen,
      appBar: AppBar(
        backgroundColor: AppColors.bgCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.greenPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Official Certificate',
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              RepaintBoundary(
                key: _repKey,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment(-0.5, -0.8),
                      end: Alignment(0.5, 1.0),
                      colors: [
                        Color(0xFF0D3320), // Very dark green
                        Color(0xFF1A6B3C), // greenPrimary
                        Color(0xFF0D3320),
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.greenBright.withValues(alpha: 0.4), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.greenPrimary.withValues(alpha: 0.25),
                        blurRadius: 30,
                        spreadRadius: -10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Trophy icon
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.10),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                        ),
                        child: const Icon(Icons.workspace_premium, size: 36, color: AppColors.greenMint),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'VERIFIED GIG CREDIT SCORE',
                        style: AppTypography.sectionLabel.copyWith(
                          color: AppColors.greenMint,
                          letterSpacing: 2,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),

                      // Score number
                      Text(
                        report.finalScore.toString(),
                        style: AppTypography.displayLarge.copyWith(
                          fontSize: 72,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: gradeColor.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: gradeColor.withValues(alpha: 0.40)),
                        ),
                        child: Text(
                          'Grade ${report.grade}  •  ${report.riskBand} Risk',
                          style: TextStyle(
                            color: gradeColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),
                      Divider(color: Colors.white.withValues(alpha: 0.15)),
                      const SizedBox(height: 20),

                      // Details
                      _RowItem(label: 'Cert ID:', val: report.proofId),
                      const SizedBox(height: 10),
                      _RowItem(
                        label: 'Issued:',
                        val: '${report.generatedAt.day}-${report.generatedAt.month}-${report.generatedAt.year}',
                      ),
                      const SizedBox(height: 10),
                      _RowItem(
                        label: 'Data Integrity:',
                        val: '${(report.overallConfidence * 100).toInt()}% Verified',
                      ),

                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shield, size: 14,
                              color: Colors.white.withValues(alpha: 0.50)),
                          const SizedBox(width: 6),
                          Text(
                            'Powered by GigCredit Engine',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SecondaryButton(
                label: 'Export PNG to Gallery',
                onPressed: _exportAsImage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  final String label;
  final String val;
  const _RowItem({required this.label, required this.val});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
          color: Colors.white.withValues(alpha: 0.50),
          fontSize: 13,
        )),
        Text(val, style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        )),
      ],
    );
  }
}
