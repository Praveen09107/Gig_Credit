import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/buttons/secondary_button.dart';
import '../../../state/score_provider.dart';

/// P7-03: Certificate Screen
/// A highly stylized official "certificate" view of the score that can be saved.
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
        // In a real app: share or save to gallery
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Certificate saved to gallery (Demo)')),
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
      return const Scaffold(body: Center(child: Text('No report data')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Official Certificate'),
        backgroundColor: Colors.transparent,
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
                    color: const Color(0xFF151821), // Dark rich blue-grey
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.accent, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: -10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.workspace_premium, size: 64, color: AppColors.accent),
                      const SizedBox(height: 16),
                      Text(
                        'VERIFIED GIG CREDIT SCORE',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.accent,
                          letterSpacing: 2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        report.finalScore.toString(),
                        style: AppTypography.displayLarge.copyWith(
                          fontSize: 80,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Score Grade: ${report.grade}',
                        style: AppTypography.titleLarge.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 32),
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 24),
                      _RowItem(label: 'Cert ID:', val: report.proofId),
                      const SizedBox(height: 8),
                      _RowItem(
                        label: 'Issued:',
                        val: '${report.generatedAt.day}-${report.generatedAt.month}-${report.generatedAt.year}',
                      ),
                      const SizedBox(height: 8),
                      _RowItem(label: 'Data Integrity:', val: '${(report.overallConfidence * 100).toInt()}% Verified'),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shield, size: 16, color: AppColors.gradeA),
                          const SizedBox(width: 8),
                          Text(
                            'Powered by GigCredit Engine',
                            style: AppTypography.labelSmall.copyWith(color: Colors.white54),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
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
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
