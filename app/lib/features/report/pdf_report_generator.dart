import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/score_report_model.dart';

/// P10-01: PDF Report Generator
/// Generates a shareable PDF report matching the on-screen score report.
class PdfReportGenerator {
  static Future<Uint8List> generate(ScoreReportModel report) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(report),
        footer: (context) => _buildFooter(report, context),
        build: (context) => [
          _buildScoreSection(report),
          pw.SizedBox(height: 20),
          _buildPillarSection(report),
          pw.SizedBox(height: 20),
          _buildFactorsSection(report),
          pw.SizedBox(height: 20),
          _buildSuggestionsSection(report),
        ],
      ),
    );

    return pdf.save();
  }

  /// Share PDF directly via OS share sheet
  static Future<void> shareReport(ScoreReportModel report) async {
    final bytes = await generate(report);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'GigCredit_Report_${report.proofId}.pdf',
    );
  }

  /// Print or preview PDF
  static Future<void> printReport(ScoreReportModel report) async {
    final bytes = await generate(report);
    await Printing.layoutPdf(onLayout: (_) => bytes);
  }

  // ── PDF Sections ──

  static pw.Widget _buildHeader(ScoreReportModel report) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('GigCredit', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.teal)),
              pw.Text('Verified Credit Report', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Proof ID: ${report.proofId}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
              pw.Text('Generated: ${_formatDate(report.generatedAt)}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
              pw.Text('Confidence: ${(report.overallConfidence * 100).toStringAsFixed(0)}%', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildScoreSection(ScoreReportModel report) {
    final gradeColor = _gradeColor(report.grade);
    return pw.Container(
      padding: const pw.EdgeInsets.all(24),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 80,
            height: 80,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              border: pw.Border.all(color: gradeColor, width: 3),
            ),
            child: pw.Center(
              child: pw.Text(
                '${report.finalScore}',
                style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: gradeColor),
              ),
            ),
          ),
          pw.SizedBox(width: 24),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Credit Score', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('Grade: ${report.grade}  •  ${report.riskBand}', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                pw.SizedBox(height: 4),
                pw.Text('Score Range: 300 – 900', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPillarSection(ScoreReportModel report) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Pillar Breakdown', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 12),
        ...report.pillars.map((pillar) {
          final pct = pillar.maxScore > 0 ? pillar.score / pillar.maxScore : 0.0;
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Row(
              children: [
                pw.SizedBox(width: 140, child: pw.Text(pillar.title, style: const pw.TextStyle(fontSize: 11))),
                pw.Expanded(
                  child: pw.Stack(
                    children: [
                      pw.Container(height: 12, decoration: pw.BoxDecoration(color: PdfColors.grey200, borderRadius: pw.BorderRadius.circular(6))),
                      pw.Container(
                        height: 12,
                        width: pct * 280,
                        decoration: pw.BoxDecoration(color: PdfColors.teal, borderRadius: pw.BorderRadius.circular(6)),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Text('${pillar.score}/${pillar.maxScore}', style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          );
        }),
      ],
    );
  }

  static pw.Widget _buildFactorsSection(ScoreReportModel report) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Top Strengths', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
              pw.SizedBox(height: 8),
              ...report.topStrengths.map((f) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('✓ ${f.featureName}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    pw.Text(f.description, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                  ],
                ),
              )),
            ],
          ),
        ),
        pw.SizedBox(width: 16),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Areas to Improve', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.orange800)),
              pw.SizedBox(height: 8),
              ...report.topConcerns.map((f) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('△ ${f.featureName}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    pw.Text(f.description, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                  ],
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSuggestionsSection(ScoreReportModel report) {
    if (report.tailoredSuggestions.isEmpty) return pw.SizedBox();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Personalized Suggestions', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        ...report.tailoredSuggestions.asMap().entries.map((entry) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 4),
          child: pw.Text('${entry.key + 1}. ${entry.value}', style: const pw.TextStyle(fontSize: 11)),
        )),
      ],
    );
  }

  static pw.Widget _buildFooter(ScoreReportModel report, pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('GigCredit — Verified Credit for the Gig Economy', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
          pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
        ],
      ),
    );
  }

  static String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';

  static PdfColor _gradeColor(String grade) {
    switch (grade) {
      case 'S': return PdfColors.teal;
      case 'A': return PdfColors.green700;
      case 'B': return PdfColors.lightGreen700;
      case 'C': return PdfColors.orange;
      case 'D': return PdfColors.deepOrange;
      default: return PdfColors.red;
    }
  }
}
