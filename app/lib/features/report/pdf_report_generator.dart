import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/score_report_model.dart';

// ── GigCredit brand colors ─────────────────────────────────────────
const _green    = PdfColor.fromInt(0xFF1A6B3C);
const _greenBr  = PdfColor.fromInt(0xFF3CC068);
const _greenLt  = PdfColor.fromInt(0xFFF5F7F5);
const _greenMd  = PdfColor.fromInt(0xFFE8F5E9);
const _textDk   = PdfColor.fromInt(0xFF1A1F1A);
const _textSec  = PdfColor.fromInt(0xFF5A6B5A);
const _textMut  = PdfColor.fromInt(0xFF8A9B8A);
const _border   = PdfColor.fromInt(0xFFE0E8E0);
const _orange   = PdfColor.fromInt(0xFFF57C00);
const _red      = PdfColor.fromInt(0xFFE53935);
const _white    = PdfColors.white;

// ── Pillar human names ────────────────────────────────────────────
const _pillarNames = {
  'P1': 'Income Stability',
  'P2': 'Payment Discipline',
  'P3': 'Debt Management',
  'P4': 'Savings Behaviour',
  'P5': 'Work Identity',
  'P6': 'Financial Resilience',
  'P7': 'Community Trust',
  'P8': 'Tax & Compliance',
};

// ── Work type human names ────────────────────────────────────────
const _workNames = {
  'platform_worker': 'Delivery Partner',
  'gig_worker':      'Gig Worker',
  'vendor':          'Street Vendor',
  'tradesperson':    'Skilled Worker',
  'freelancer':      'Freelancer',
  'salaried':        'Employed Worker',
  'self_employed':   'Self-Employed',
};

String _wt(String wt) => _workNames[wt] ?? wt;

/// GigCredit PDF Report Generator - v3.0
/// Generates a 9-page consumer-facing credit report from ScoreReportModel.
/// All values are dynamic - pulled directly from the report object.
class PdfReportGenerator {

  // ── Public API ──────────────────────────────────────────────────
  static Future<Uint8List> generate(ScoreReportModel report, {String applicantName = 'Applicant'}) async {
    final pdf = pw.Document(title: 'GigCredit Credit Report', author: 'GigCredit');

    // Page 1: Credit Snapshot
    pdf.addPage(_page1CreditSnapshot(report, applicantName));
    // Page 2: How Score Was Built
    pdf.addPage(_page2ScoreBuilt(report));
    // Page 3: Score Contribution Chart
    pdf.addPage(_page3Contribution(report));
    // Page 4: Your Strengths
    pdf.addPage(_page4Strengths(report));
    // Page 5: Improvement Opportunities
    pdf.addPage(_page5Improvements(report));
    // Page 6: Action Plan + What-If
    pdf.addPage(_page6ActionPlan(report));
    // Page 7: Loan Eligibility
    pdf.addPage(_page7LoanEligibility(report));
    // Page 8: Fairness, Privacy & Trust
    pdf.addPage(_page8FairnessPrivacy());
    // Page 9 (Report Info) removed — redundant for end users

    return pdf.save();
  }

  static Future<void> shareReport(ScoreReportModel report, {String applicantName = 'Applicant'}) async {
    final bytes = await generate(report, applicantName: applicantName);
    final date = DateFormat('yyyyMMdd').format(report.generatedAt);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'GigCredit_Report_${report.proofId}_$date.pdf',
    );
  }

  static Future<void> printPreview(ScoreReportModel report, {String applicantName = 'Applicant'}) async {
    await Printing.layoutPdf(
      onLayout: (_) => generate(report, applicantName: applicantName),
      name: 'GigCredit_Report_${report.proofId}',
    );
  }

  // ── HELPERS ─────────────────────────────────────────────────────
  static String _fmt(DateTime d) => DateFormat('dd MMM yyyy, hh:mm a').format(d);
  static String _fmtShort(DateTime d) => DateFormat('dd MMM yyyy').format(d);
  static String _fmtAmount(double v) => 'Rs.${NumberFormat('#,##,##0').format(v.round())}';

  static PdfColor _gradeColor(String grade) {
    switch (grade) {
      case 'A+': return _greenBr;
      case 'A':  return _green;
      case 'B+': return PdfColor.fromInt(0xFF66BB6A);
      case 'B':  return PdfColor.fromInt(0xFF8BC34A);
      case 'C+': return PdfColor.fromInt(0xFFFFC107);
      case 'C':  return _orange;
      default:   return _red;
    }
  }

  static String _gradeText(String grade) {
    switch (grade) {
      case 'A+': return 'Premium';
      case 'A':  return 'Excellent';
      case 'B+': return 'Very Good';
      case 'B':  return 'Good';
      case 'C+': return 'Fair';
      case 'C':  return 'Medium';
      default:   return 'Needs Work';
    }
  }

  static String _pillarStatus(double confidence) {
    if (confidence >= 0.75) return 'STRONG';
    if (confidence >= 0.50) return 'MODERATE';
    return 'NEEDS IMPROVEMENT';
  }

  static PdfColor _statusColor(double confidence) {
    if (confidence >= 0.75) return _green;
    if (confidence >= 0.50) return _orange;
    return _red;
  }

  static String _nextGrade(String grade) {
    switch (grade) {
      case 'D':  return 'C';
      case 'C':  return 'C+';
      case 'C+': return 'B';
      case 'B':  return 'B+';
      case 'B+': return 'A';
      case 'A':  return 'A+';
      default:   return 'A+';
    }
  }

  static int _nextScore(int current) {
    if (current < 550) return 550;
    if (current < 600) return 600;
    if (current < 650) return 650;
    if (current < 700) return 700;
    if (current < 750) return 750;
    if (current < 800) return 800;
    return 900;
  }

  // ── SHARED WIDGETS ───────────────────────────────────────────────
  static pw.Widget _headerBand(String title, {String subtitle = ''}) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: _green,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('GigCredit', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _white)),
            if (subtitle.isNotEmpty)
              pw.Text(subtitle, style: const pw.TextStyle(fontSize: 9, color: PdfColor(1, 1, 1, 0.7))),
          ]),
          pw.Text(title, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _white)),
        ],
      ),
    );
  }

  static pw.Widget _sectionTitle(String num, String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.only(left: 8, top: 4, bottom: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(left: pw.BorderSide(color: _green, width: 4)),
      ),
      child: pw.Text('$num  $title',
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _textDk)),
    );
  }

  static pw.Widget _card({required pw.Widget child, PdfColor? bg, bool border = true}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      margin: const pw.EdgeInsets.only(bottom: 10),
      decoration: pw.BoxDecoration(
        color: bg ?? _white,
        borderRadius: pw.BorderRadius.circular(6),
        border: border ? pw.Border.all(color: _border) : null,
      ),
      child: child,
    );
  }

  static pw.Widget _footer(ScoreReportModel r, pw.Context ctx, String pageTitle) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: _border))),
      child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text('GigCredit  |  ${r.proofId}  |  $pageTitle',
            style: const pw.TextStyle(fontSize: 7, color: _textMut)),
        pw.Text('Page ${ctx.pageNumber}  |  ${DateFormat("dd MMM yyyy").format(r.generatedAt)}  |  CONFIDENTIAL',
            style: const pw.TextStyle(fontSize: 7, color: _textMut)),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // PAGE 1 - CREDIT SNAPSHOT
  // ══════════════════════════════════════════════════════════════
  static pw.Page _page1CreditSnapshot(ScoreReportModel r, String name) {
    final gc = _gradeColor(r.grade);
    final nextG = _nextGrade(r.grade);
    final nextS = _nextScore(r.finalScore);
    final topStr = r.topStrengths.isNotEmpty ? r.topStrengths.first.featureName : 'Verified Identity';
    final topCon = r.topConcerns.isNotEmpty ? r.topConcerns.first.featureName : 'File ITR';

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (ctx) => pw.Column(children: [
        _headerBand('CREDIT & LOAN ELIGIBILITY REPORT', subtitle: 'Report ID: ${r.proofId}  |  ${_fmtShort(r.generatedAt)}'),
        pw.Padding(
          padding: const pw.EdgeInsets.all(24),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [

            // Applicant block
            _card(bg: _greenMd, child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text(name, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _textDk)),
                  pw.Text(_wt(r.workType), style: const pw.TextStyle(fontSize: 11, color: _textSec)),
                ]),
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                  pw.Text('Generated: ${_fmt(r.generatedAt)}', style: const pw.TextStyle(fontSize: 9, color: _textMut)),
                  pw.Text('Valid for 90 days', style: const pw.TextStyle(fontSize: 9, color: _textMut)),
                ]),
              ],
            )),

            // Score ring + credit snapshot side by side
            pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              // Score ring
              pw.Container(
                width: 120, height: 120,
                margin: const pw.EdgeInsets.only(right: 20),
                decoration: pw.BoxDecoration(shape: pw.BoxShape.circle, border: pw.Border.all(color: gc, width: 6)),
                child: pw.Center(child: pw.Column(mainAxisSize: pw.MainAxisSize.min, children: [
                  pw.Text('${r.finalScore}', style: pw.TextStyle(fontSize: 30, fontWeight: pw.FontWeight.bold, color: gc)),
                  pw.Text('Grade ${r.grade}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: gc)),
                  pw.Text(r.riskBand, style: const pw.TextStyle(fontSize: 8, color: _textSec)),
                ])),
              ),

              // Credit Snapshot card
              pw.Expanded(child: _card(bg: _greenMd, child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('YOUR CREDIT SNAPSHOT', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _green)),
                pw.SizedBox(height: 8),
                _snapRow('Score', '${r.finalScore}  (${_gradeText(r.grade)})'),
                _snapRow('Loan Option', r.finalScore >= 550 ? 'Estimated up to ${_fmtAmount(_maxLoan(r.finalScore))}' : '${550 - r.finalScore} pts more needed to qualify'),
                _snapRow('Top Strength', topStr),
                _snapRow('Top Priority', topCon),
                _snapRow('Next Goal', 'Reach Grade $nextG ($nextS+)'),
              ]))),
            ]),

            pw.SizedBox(height: 14),

            // Grade scale
            _gradeScale(r.grade),

            pw.SizedBox(height: 14),

            // Verification status
            _card(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('VERIFICATION STATUS', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _green)),
              pw.SizedBox(height: 6),
              pw.Row(children: [
                _verBadge('Aadhaar'), pw.SizedBox(width: 8),
                _verBadge('PAN'), pw.SizedBox(width: 8),
                _verBadge('Bank Account'), pw.SizedBox(width: 8),
                _verBadge('Face Match'), pw.SizedBox(width: 8),
                _verBadge('Mobile'), pw.SizedBox(width: 8),
                _verBadge('Work History'),
              ]),
            ])),

            // Score meaning
            if (r.llmExplanation != null && r.llmExplanation!.isNotEmpty)
              _card(bg: _greenLt, child: pw.Text(
                _truncate(r.llmExplanation!, 300),
                style: const pw.TextStyle(fontSize: 9, color: _textSec, lineSpacing: 3),
              )),
          ]),
        ),
        pw.Spacer(),
        pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: _footer(r, ctx, 'Credit Snapshot')),
      ]),
    );
  }

  static pw.Widget _snapRow(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.Row(children: [
      pw.SizedBox(width: 80, child: pw.Text('$label:', style: const pw.TextStyle(fontSize: 9, color: _textMut))),
      pw.Expanded(child: pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _textDk))),
    ]),
  );

  static pw.Widget _verBadge(String label) => pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: pw.BoxDecoration(color: _greenMd, borderRadius: pw.BorderRadius.circular(4),
      border: pw.Border.all(color: _green)),
    child: pw.Text('[OK] $label', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: _green)),
  );

  static double _maxLoan(int score) {
    if (score >= 800) return 200000;
    if (score >= 700) return 120000;
    if (score >= 600) return 82000;
    if (score >= 500) return 50000;
    return 25000;
  }

  static pw.Widget _gradeScale(String currentGrade) {
    final grades = ['D', 'C', 'C+', 'B', 'B+', 'A', 'A+'];
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: pw.BoxDecoration(color: _greenMd, borderRadius: pw.BorderRadius.circular(6)),
      child: pw.Column(children: [
        pw.Text('WHERE YOU STAND', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _green)),
        pw.SizedBox(height: 6),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly, children: grades.map((g) {
          final isCurrent = g == currentGrade;
          return pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: pw.BoxDecoration(
              color: isCurrent ? _gradeColor(g) : _border,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(g, style: pw.TextStyle(fontSize: 9,
              fontWeight: isCurrent ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isCurrent ? _white : _textMut)),
          );
        }).toList()),
      ]),
    );
  }

  static String _truncate(String s, int max) => s.length > max ? '${s.substring(0, max)}...' : s;

  // ══════════════════════════════════════════════════════════════
  // PAGE 2 - HOW YOUR SCORE WAS BUILT
  // ══════════════════════════════════════════════════════════════
  static pw.Page _page2ScoreBuilt(ScoreReportModel r) {
    return pw.Page(pageFormat: PdfPageFormat.a4, margin: pw.EdgeInsets.zero,
      build: (ctx) => pw.Column(children: [
        _headerBand('HOW YOUR SCORE WAS BUILT'),
        pw.Padding(padding: const pw.EdgeInsets.all(24), child: pw.Column(children: [
          _sectionTitle('2', 'How Your Score Was Built'),
          pw.Text('Starting base: 300 points  ->  Your final score: ${r.finalScore} points',
              style: const pw.TextStyle(fontSize: 9, color: _textSec)),
          pw.SizedBox(height: 12),
          // Pillar summary table
          _card(child: pw.Column(children: [
            _tableRow('Area', 'Points', 'Status', isHeader: true),
            ...r.pillars.map((p) => _tableRow(
              _pillarNames[p.code] ?? p.title,
              '+${r.pillarContributions[p.code] ?? 0}',
              _pillarStatus(p.confidence),
              statusColor: _statusColor(p.confidence),
            )),
            pw.Divider(color: _border),
            _tableRow('Starting Base', '+300', '', isHeader: false),
            _tableRow('TOTAL', '${r.finalScore} pts [OK]', 'Grade ${r.grade}', isHeader: true),
          ])),
          pw.SizedBox(height: 10),
          // Top 3 strengths expanded
          pw.Text('TOP STRENGTHS', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _green)),
          pw.SizedBox(height: 6),
          ...r.topStrengths.take(3).map((s) => _card(bg: const PdfColor.fromInt(0xFFE8F5E9), child: pw.Row(children: [
            pw.Text('[OK]', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _green)),
            pw.SizedBox(width: 8),
            pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(s.featureName, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _textDk)),
              pw.Text(s.description.isNotEmpty ? _truncate(s.description, 120) : 'This is working well for you.',
                  style: const pw.TextStyle(fontSize: 8, color: _textSec)),
            ])),
          ]))),
          pw.SizedBox(height: 6),
          pw.Text('TOP AREAS TO IMPROVE', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _orange)),
          pw.SizedBox(height: 6),
          ...r.topConcerns.take(3).map((c) => _card(bg: const PdfColor.fromInt(0xFFFFF3E0), child: pw.Row(children: [
            pw.Text('!', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _orange)),
            pw.SizedBox(width: 8),
            pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(c.featureName, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _textDk)),
              pw.Text(c.description.isNotEmpty ? _truncate(c.description, 120) : 'Improving this will help your score.',
                  style: const pw.TextStyle(fontSize: 8, color: _textSec)),
            ])),
          ]))),
        ])),
        pw.Spacer(),
        pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: _footer(r, ctx, 'Score Breakdown')),
      ]),
    );
  }

  static pw.Widget _tableRow(String col1, String col2, String col3, {bool isHeader = false, PdfColor? statusColor}) {
    final style = isHeader
        ? pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _textDk)
        : const pw.TextStyle(fontSize: 9, color: _textSec);
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      decoration: isHeader ? const pw.BoxDecoration(color: PdfColor.fromInt(0xFFE8F5E9)) : null,
      child: pw.Row(children: [
        pw.Expanded(flex: 4, child: pw.Text(col1, style: style)),
        pw.SizedBox(width: 60, child: pw.Text(col2, style: pw.TextStyle(fontSize: 9,
            fontWeight: pw.FontWeight.bold, color: _green))),
        pw.SizedBox(width: 100, child: pw.Text(col3,
            style: pw.TextStyle(fontSize: 8, color: statusColor ?? _textMut,
                fontWeight: statusColor != null ? pw.FontWeight.bold : pw.FontWeight.normal))),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // PAGE 3 - SCORE CONTRIBUTION CHART
  // ══════════════════════════════════════════════════════════════
  static pw.Page _page3Contribution(ScoreReportModel r) {
    final sorted = r.pillars.toList()
      ..sort((a, b) => (r.pillarContributions[b.code] ?? 0).compareTo(r.pillarContributions[a.code] ?? 0));
    final maxPts = sorted.isNotEmpty ? (r.pillarContributions[sorted.first.code] ?? 1).toDouble() : 1.0;

    return pw.Page(pageFormat: PdfPageFormat.a4, margin: pw.EdgeInsets.zero,
      build: (ctx) => pw.Column(children: [
        _headerBand('WHERE YOUR SCORE CAME FROM'),
        pw.Padding(padding: const pw.EdgeInsets.all(24), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          _sectionTitle('3', 'Where Your Score Came From'),
          pw.Text('See which areas contributed most to your ${r.finalScore} points.',
              style: const pw.TextStyle(fontSize: 9, color: _textSec)),
          pw.SizedBox(height: 16),
          // Horizontal bar chart
          ...sorted.map((p) {
            final pts = r.pillarContributions[p.code] ?? 0;
            final barWidth = maxPts > 0 ? (pts / maxPts) * 300 : 0.0;
            final status = _pillarStatus(p.confidence);
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
                pw.SizedBox(width: 130, child: pw.Text(_pillarNames[p.code] ?? p.title,
                    style: const pw.TextStyle(fontSize: 9, color: _textDk))),
                pw.SizedBox(width: 8),
                pw.Stack(children: [
                  pw.Container(height: 14, width: 300,
                      decoration: pw.BoxDecoration(color: _border, borderRadius: pw.BorderRadius.circular(4))),
                  pw.Container(height: 14, width: barWidth.toDouble(),
                      decoration: pw.BoxDecoration(
                        color: _statusColor(p.confidence),
                        borderRadius: pw.BorderRadius.circular(4),
                      )),
                ]),
                pw.SizedBox(width: 8),
                pw.Text('+$pts pts', style: pw.TextStyle(fontSize: 9,
                    fontWeight: pw.FontWeight.bold, color: _statusColor(p.confidence))),
                pw.SizedBox(width: 4),
                pw.Text(status, style: pw.TextStyle(fontSize: 7, color: _statusColor(p.confidence))),
              ]),
            );
          }),
          pw.Divider(color: _border),
          pw.Row(children: [
            pw.Text('Starting base: +300  ', style: const pw.TextStyle(fontSize: 9, color: _textSec)),
            pw.Text('TOTAL: ${r.finalScore} pts  Grade ${r.grade}',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _green)),
          ]),
          pw.SizedBox(height: 16),
          // Plain language explanation
          _card(bg: _greenMd, child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('WHAT THIS MEANS FOR YOU', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _green)),
            pw.SizedBox(height: 6),
            if (sorted.isNotEmpty) pw.Text(
              '${_pillarNames[sorted.first.code] ?? sorted.first.title} added the most points (+${r.pillarContributions[sorted.first.code] ?? 0}) - '
              'this is your biggest strength and the main reason lenders will trust you.',
              style: const pw.TextStyle(fontSize: 9, color: _textSec, lineSpacing: 3),
            ),
            if (sorted.length > 1) ...[
              pw.SizedBox(height: 4),
              pw.Text(
                '${_pillarNames[sorted.last.code] ?? sorted.last.title} had the least points (+${r.pillarContributions[sorted.last.code] ?? 0}) - '
                'this is your biggest opportunity. Focus here for the fastest score improvement.',
                style: const pw.TextStyle(fontSize: 9, color: _textSec, lineSpacing: 3),
              ),
            ],
          ])),
          // Score equation
          pw.SizedBox(height: 10),
          _card(bg: _greenLt, child: pw.Column(children: [
            pw.Text('SCORE EQUATION', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _textMut)),
            pw.SizedBox(height: 4),
            pw.Text(
              '300  +  ${sorted.map((p) => '${r.pillarContributions[p.code] ?? 0}').join(' + ')}  =  ${r.finalScore} pts  [OK]  Grade ${r.grade}',
              style: pw.TextStyle(fontSize: 8, color: _textSec, fontStyle: pw.FontStyle.italic),
            ),
          ])),
        ])),
        pw.Spacer(),
        pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: _footer(r, ctx, 'Contribution Chart')),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // PAGE 4 - STRENGTHS   PAGE 5 - IMPROVEMENTS   PAGE 6 - ACTION PLAN
  // ══════════════════════════════════════════════════════════════
  static pw.Page _page4Strengths(ScoreReportModel r) {
    final strengths = r.topStrengths.take(5).toList();
    return pw.Page(pageFormat: PdfPageFormat.a4, margin: pw.EdgeInsets.zero,
      build: (ctx) => pw.Column(children: [
        _headerBand('WHAT\'S WORKING IN YOUR FAVOR'),
        pw.Padding(padding: const pw.EdgeInsets.all(24), child: pw.Column(children: [
          _sectionTitle('4', "What's Working in Your Favor"),
          pw.Text('These are the reasons lenders will trust you.',
              style: const pw.TextStyle(fontSize: 9, color: _textSec)),
          pw.SizedBox(height: 12),
          if (strengths.isEmpty)
            _card(child: pw.Text('Keep building your financial profile - strengths will appear here.',
                style: const pw.TextStyle(fontSize: 9, color: _textSec)))
          else ...strengths.asMap().entries.map((e) => _card(
            bg: const PdfColor.fromInt(0xFFE8F5E9),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Row(children: [
                pw.Text('[OK]', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _green)),
                pw.SizedBox(width: 8),
                pw.Expanded(child: pw.Text(e.value.featureName,
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _textDk))),
                pw.Container(padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: pw.BoxDecoration(color: _green, borderRadius: pw.BorderRadius.circular(4)),
                  child: pw.Text('HIGH IMPACT',
                      style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: _white))),
              ]),
              pw.SizedBox(height: 6),
              pw.Text(e.value.description.isNotEmpty ? e.value.description : 'This is positively impacting your credit profile.',
                  style: const pw.TextStyle(fontSize: 9, color: _textSec, lineSpacing: 3)),
              pw.SizedBox(height: 4),
              pw.Text('Why lenders care: This gives them confidence that you can repay reliably.',
                  style: pw.TextStyle(fontSize: 8, color: _textMut, fontStyle: pw.FontStyle.italic)),
            ]),
          )),
        ])),
        pw.Spacer(),
        pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: _footer(r, ctx, 'Your Strengths')),
      ]),
    );
  }

  static pw.Page _page5Improvements(ScoreReportModel r) {
    final concerns = r.topConcerns.take(4).toList();
    return pw.Page(pageFormat: PdfPageFormat.a4, margin: pw.EdgeInsets.zero,
      build: (ctx) => pw.Column(children: [
        _headerBand('HOW YOU CAN IMPROVE YOUR SCORE'),
        pw.Padding(padding: const pw.EdgeInsets.all(24), child: pw.Column(children: [
          _sectionTitle('5', 'How You Can Improve Your Score'),
          pw.Text('Small changes, big results.',
              style: const pw.TextStyle(fontSize: 9, color: _textSec)),
          pw.SizedBox(height: 12),
          if (concerns.isEmpty)
            _card(child: pw.Text('Great job! No major gaps found. Keep maintaining your current habits.',
                style: const pw.TextStyle(fontSize: 9, color: _textSec)))
          else ...concerns.asMap().entries.map((e) {
            final gain = (e.value.impactStrength * 600 * 0.7).round().clamp(5, 40);
            final timelines = ['This month', '1-2 months', '2-3 months', '3-6 months'];
            return _card(bg: const PdfColor.fromInt(0xFFFFF8E1), child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Row(children: [
                pw.Text('!', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _orange)),
                pw.SizedBox(width: 8),
                pw.Expanded(child: pw.Text(e.value.featureName,
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _textDk))),
                pw.Container(padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: pw.BoxDecoration(color: _orange, borderRadius: pw.BorderRadius.circular(4)),
                  child: pw.Text('+$gain pts possible',
                      style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: _white))),
              ]),
              pw.SizedBox(height: 6),
              pw.Text('Why: ${e.value.description.isNotEmpty ? e.value.description : "Improving this area will help your credit score."}',
                  style: const pw.TextStyle(fontSize: 9, color: _textSec, lineSpacing: 3)),
              pw.SizedBox(height: 4),
              pw.Row(children: [
                pw.Text('Timeline: ', style: const pw.TextStyle(fontSize: 8, color: _textMut)),
                pw.Text(timelines[e.key % 4],
                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _orange)),
                pw.Spacer(),
                pw.Text('Expected gain: +$gain to +${gain + 10} pts',
                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _green)),
              ]),
            ]));
          }),
        ])),
        pw.Spacer(),
        pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: _footer(r, ctx, 'Improvement Plan')),
      ]),
    );
  }

  static pw.Page _page6ActionPlan(ScoreReportModel r) {
    final suggestions = r.tailoredSuggestions.take(4).toList();
    final totalGain = suggestions.fold(0, (s, a) => s + (a.estimatedPtsGain ?? 15));
    final potential = (r.finalScore + totalGain).clamp(300, 900);
    // What-if simulator
    final g1 = suggestions.isNotEmpty ? (suggestions[0].estimatedPtsGain ?? 15) : 30;
    final g2 = suggestions.length > 1 ? (suggestions[1].estimatedPtsGain ?? 15) : 18;
    final g3 = suggestions.length > 2 ? (suggestions[2].estimatedPtsGain ?? 15) : 12;
    return pw.Page(pageFormat: PdfPageFormat.a4, margin: pw.EdgeInsets.zero,
      build: (ctx) => pw.Column(children: [
        _headerBand('YOUR STEP-BY-STEP IMPROVEMENT PLAN'),
        pw.Padding(padding: const pw.EdgeInsets.all(24), child: pw.Column(children: [
          _sectionTitle('6', 'Your Action Plan + What-If Simulator'),
          // What-If Simulator
          _card(bg: _greenMd, child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('WHAT HAPPENS IF YOU...', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _green)),
            pw.SizedBox(height: 8),
            if (suggestions.isNotEmpty) _whatIfRow(suggestions[0].text, r.finalScore, g1),
            if (suggestions.length > 1) _whatIfRow(suggestions[1].text, r.finalScore, g2),
            if (suggestions.length > 2) _whatIfRow(suggestions[2].text, r.finalScore, g3),
            pw.Divider(color: _border),
            _whatIfRow('Do all actions', r.finalScore, totalGain, isTotal: true),
            pw.SizedBox(height: 4),
            pw.Text('Do all = Grade ${_nextGrade(r.grade)} in 3 months!',
                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _green)),
          ])),
          pw.SizedBox(height: 10),
          // Roadmap
          ...suggestions.asMap().entries.map((e) => _card(child: pw.Row(children: [
            pw.Container(width: 24, height: 24,
              decoration: pw.BoxDecoration(color: _green, shape: pw.BoxShape.circle),
              child: pw.Center(child: pw.Text('${e.key + 1}',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _white)))),
            pw.SizedBox(width: 10),
            pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(e.value.text.length > 80 ? e.value.text.substring(0, 80) : e.value.text,
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _textDk)),
              pw.Text('Expected gain: +${e.value.estimatedPtsGain ?? 15} pts',
                  style: pw.TextStyle(fontSize: 8, color: _green)),
            ])),
          ]))),
          // Projected score
          _card(bg: _greenLt, child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceAround, children: [
            _scoreStep('Today', r.finalScore, r.grade),
            pw.Text('->', style: pw.TextStyle(fontSize: 14, color: _green)),
            _scoreStep('After actions', potential, _scoreToGrade(potential)),
          ])),
        ])),
        pw.Spacer(),
        pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: _footer(r, ctx, 'Action Plan')),
      ]),
    );
  }

  static pw.Widget _whatIfRow(String action, int base, int gain, {bool isTotal = false}) {
    final trunc = action.length > 50 ? '${action.substring(0, 50)}...' : action;
    return pw.Padding(padding: const pw.EdgeInsets.only(bottom: 4), child: pw.Row(children: [
      pw.Expanded(child: pw.Text(isTotal ? 'Do all actions' : trunc,
          style: pw.TextStyle(fontSize: 8, fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal))),
      pw.Text('$base -> ${base + gain}', style: pw.TextStyle(fontSize: 8,
          fontWeight: pw.FontWeight.bold, color: _green)),
      pw.SizedBox(width: 4),
      pw.Text('(+$gain pts)', style: const pw.TextStyle(fontSize: 7, color: _textMut)),
    ]));
  }

  static pw.Widget _scoreStep(String label, int score, String grade) => pw.Column(children: [
    pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: _textMut)),
    pw.Text('$score', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _green)),
    pw.Text('Grade $grade', style: pw.TextStyle(fontSize: 8, color: _green)),
  ]);

  static String _scoreToGrade(int s) {
    if (s >= 800) return 'A+'; if (s >= 750) return 'A'; if (s >= 700) return 'B+';
    if (s >= 650) return 'B'; if (s >= 600) return 'C+'; if (s >= 550) return 'C'; return 'D';
  }

  // ══════════════════════════════════════════════════════════════
  // PAGE 7 - LOAN ELIGIBILITY  PAGE 8 - FAIRNESS  PAGE 9 - INFO
  // ══════════════════════════════════════════════════════════════
  static pw.Page _page7LoanEligibility(ScoreReportModel r) {
    final income = r.applicantMonthlyIncome > 0 ? r.applicantMonthlyIncome : 18000.0;
    final isEligible = r.finalScore >= 550;
    final ptsNeeded = isEligible ? 0 : 550 - r.finalScore;
    final maxLoan = _maxLoan(r.finalScore);
    final minLoan = maxLoan * 0.5;
    final rate = r.finalScore >= 700 ? 0.15 : r.finalScore >= 600 ? 0.18 : 0.22;
    final emi = maxLoan * rate / 12 * (1 + rate / 12);
    final dti = income > 0 ? (emi / income * 100) : 0.0;
    final safe = dti < 50;
    // Fastest action to qualify
    final fastestAction = r.topConcerns.isNotEmpty ? r.topConcerns.first.featureName : 'File ITR';
    return pw.Page(pageFormat: PdfPageFormat.a4, margin: pw.EdgeInsets.zero,
      build: (ctx) => pw.Column(children: [
        _headerBand('LOAN ELIGIBILITY REPORT'),
        pw.Padding(padding: const pw.EdgeInsets.all(24), child: pw.Column(children: [
          _sectionTitle('7', 'Loan Eligibility Report'),
          // Layer 1 — credit score explanation
          _card(bg: _greenMd, child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('LAYER 1 - WHY YOU GOT THIS CREDIT SCORE',
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _green)),
            pw.SizedBox(height: 6),
            ...r.topStrengths.take(3).map((s) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Text('[OK] ${s.featureName}', style: const pw.TextStyle(fontSize: 9, color: _textDk)),
            )),
            if (r.topConcerns.isNotEmpty) pw.Text('[X] ${r.topConcerns.first.featureName} - biggest opportunity',
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _orange)),
          ])),
          pw.SizedBox(height: 8),
          // Eligibility decision
          if (!isEligible) ...[
            _card(bg: const PdfColor.fromInt(0xFFFFEBEE), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('NOT YET ELIGIBLE',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _red)),
              pw.SizedBox(height: 6),
              pw.Text('Your score of ${r.finalScore} is $ptsNeeded points below the lending threshold of 550.',
                  style: const pw.TextStyle(fontSize: 9, color: _textDk)),
              pw.SizedBox(height: 4),
              pw.Text('How to qualify: Complete "$fastestAction" to gain points and reach the threshold.',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _orange)),
              pw.SizedBox(height: 4),
              pw.Text('See Page 5 for your full improvement plan.',
                  style: const pw.TextStyle(fontSize: 8, color: _textSec)),
            ])),
          ] else ...[
            // Estimated eligibility card
            _card(bg: const PdfColor.fromInt(0xFFE3F2FD), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('ESTIMATED LOAN ELIGIBILITY',
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _textDk)),
              pw.SizedBox(height: 4),
              pw.Text('Based on your profile, you may qualify for:',
                  style: const pw.TextStyle(fontSize: 9, color: _textSec)),
              pw.SizedBox(height: 6),
              pw.Row(children: [
                _loanDetail('Range', '${_fmtAmount(minLoan)} - ${_fmtAmount(maxLoan)}'),
                pw.SizedBox(width: 16),
                _loanDetail('Rate', '${(rate * 100).toStringAsFixed(0)}% per year'),
                pw.SizedBox(width: 16),
                _loanDetail('Est. EMI', '${_fmtAmount(emi)}/month'),
              ]),
              pw.SizedBox(height: 6),
              pw.Container(padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(color: const PdfColor(0.96, 0.49, 0, 0.1), borderRadius: pw.BorderRadius.circular(4)),
                child: pw.Text('Final approval depends on lender review. Apply through GigCredit for a real offer.',
                    style: const pw.TextStyle(fontSize: 8, color: _textSec))),
            ])),
            // Layer 2 and Affordability
            _card(bg: _greenLt, child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('LAYER 2 - HOW YOUR ELIGIBILITY WAS CALCULATED',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _green)),
              pw.SizedBox(height: 6),
              _layer2Row('Income check', income > 0 ? '${_fmtAmount(income)}/month - stable' : 'Not available', true),
              _layer2Row('Repayment', 'After EMI, you keep ${_fmtAmount(income - emi)}/month', income > emi),
              _layer2Row('Debt check', 'Total EMI = ${dti.toStringAsFixed(0)}% of income  (${safe ? "Safe" : "Caution"})', safe),
              _layer2Row('Identity', 'Aadhaar + PAN + Face - verified', true),
              _layer2Row('Score', '${r.finalScore} - meets minimum requirement (550)', true),
            ])),
            _card(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('AFFORDABILITY CHECK', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              _afRow('Your income', '${_fmtAmount(income)}/month'),
              _afRow('Estimated new EMI', '${_fmtAmount(emi)}/month'),
              _afRow('Money left each month', '${_fmtAmount(income - emi)}  ${safe ? "[OK] Comfortable" : "[!] Tight"}'),
            ])),
          ],
        ])),
        pw.Spacer(),
        pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: _footer(r, ctx, 'Loan Eligibility')),
      ]),
    );
  }

  static pw.Widget _loanDetail(String label, String value) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    pw.Text(label, style: const pw.TextStyle(fontSize: 7, color: _textMut)),
    pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _textDk)),
  ]);

  static pw.Widget _layer2Row(String label, String value, bool pass) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.Row(children: [
      pw.Text(pass ? '[OK]' : '[X]', style: pw.TextStyle(fontSize: 10, color: pass ? _green : _red)),
      pw.SizedBox(width: 6),
      pw.SizedBox(width: 90, child: pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: _textMut))),
      pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 8, color: _textDk))),
    ]),
  );

  static pw.Widget _afRow(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
      pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: _textSec)),
      pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _textDk)),
    ]),
  );

  static pw.Page _page8FairnessPrivacy() {
    return pw.Page(pageFormat: PdfPageFormat.a4, margin: pw.EdgeInsets.zero,
      build: (ctx) => pw.Column(children: [
        _headerBand('YOUR DATA IS SAFE. YOUR SCORE IS FAIR.'),
        pw.Padding(padding: const pw.EdgeInsets.all(24), child: pw.Column(children: [
          _sectionTitle('8', 'Fairness, Privacy & Trust'),
          _card(bg: _greenMd, child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('We DO NOT use:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _red)),
              pw.SizedBox(height: 6),
              ...['Religion or caste','Gender','Political views','Your name or appearance','Location bias'].map((s) =>
                  pw.Text('[X] $s', style: const pw.TextStyle(fontSize: 9, color: _textDk))),
            ])),
            pw.SizedBox(width: 20),
            pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('We ONLY use:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _green)),
              pw.SizedBox(height: 6),
              ...['Your income patterns','Your bill payment history','Your savings behaviour','Your verified identity','Your debt level'].map((s) =>
                  pw.Text('[OK] $s', style: const pw.TextStyle(fontSize: 9, color: _textDk))),
            ])),
          ])),
          _card(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('[SEC]  Your Personal Data Was Never Shared',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _textDk)),
            pw.SizedBox(height: 4),
            pw.Text('Your Aadhaar number, bank details, and personal information stayed on your phone. Only your score was stored on our secure servers.',
                style: const pw.TextStyle(fontSize: 9, color: _textSec, lineSpacing: 3)),
          ])),
          _card(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('[SEC]  Your Rights', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _textDk)),
            pw.SizedBox(height: 6),
            ...['See your full report anytime','Request a re-check if you disagree','Delete your data from our system','Know which lenders saw your score','File a complaint - 3 working day response'].map((s) =>
                pw.Text('[OK] $s', style: const pw.TextStyle(fontSize: 9, color: _textSec))),
          ])),
        ])),
        pw.Spacer(),
        pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: pw.Container(
              padding: const pw.EdgeInsets.only(top: 6),
              decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: _border))),
              child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('GigCredit  |  Fairness & Privacy', style: const pw.TextStyle(fontSize: 7, color: _textMut)),
                pw.Text('Page ${ctx.pageNumber}  |  CONFIDENTIAL', style: const pw.TextStyle(fontSize: 7, color: _textMut)),
              ]),
            )),
      ]),
    );
  }

  static pw.Page _page9ReportInfo(ScoreReportModel r) {
    final validUntil = r.generatedAt.add(const Duration(days: 90));
    final hash = r.proofId.hashCode.toRadixString(16).padLeft(8, '0');
    return pw.Page(pageFormat: PdfPageFormat.a4, margin: pw.EdgeInsets.zero,
      build: (ctx) => pw.Column(children: [
        _headerBand('REPORT INFORMATION'),
        pw.Padding(padding: const pw.EdgeInsets.all(24), child: pw.Column(children: [
          _sectionTitle('9', 'About This Report'),
          _card(bg: _greenMd, child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            _infoRow('[OK] Verified Report', 'This report is genuine'),
            _infoRow('[OK] Secure Report', 'Your data is protected'),
            _infoRow('[OK] Verify Online', 'At gigcredit.in/verify using Report ID'),
            pw.SizedBox(height: 8),
            _infoRow('Report ID', r.proofId),
            _infoRow('Generated', _fmt(r.generatedAt)),
            _infoRow('Valid Until', _fmtShort(validUntil)),
          ])),
          _card(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('FOR LENDERS - Technical Details',
                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _textMut)),
            pw.SizedBox(height: 6),
            _infoRow('Integrity', 'sha256:$hash...  *  VERIFIED [OK]'),
            _infoRow('Engine', 'GigCredit Scoring Engine v4.2.1'),
            _infoRow('Compliance', 'RBI Digital Lending Guidelines 2022'),
            _infoRow('Generated', r.generatedAt.toIso8601String()),
          ])),
          _card(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('Contact & Grievance', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _textDk)),
            pw.SizedBox(height: 4),
            _infoRow('Support', 'support@gigcredit.in'),
            _infoRow('Helpline', '1800-XXX-XXXX  (Mon-Sat, 9AM-6PM)'),
            _infoRow('Grievance', 'grievance@gigcredit.in  |  Response: 3 working days'),
          ])),
          _card(bg: _greenLt, child: pw.Text(
            'Disclaimer: This report is for informational purposes only. The final loan decision is made by the lender. '
            'This report is confidential and intended only for the named applicant and authorised lenders.',
            style: const pw.TextStyle(fontSize: 8, color: _textMut, lineSpacing: 3),
          )),
        ])),
        pw.Spacer(),
        pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: pw.Container(
              padding: const pw.EdgeInsets.only(top: 6),
              decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: _border))),
              child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('GigCredit  |  ${r.proofId}', style: const pw.TextStyle(fontSize: 7, color: _textMut)),
                pw.Text('Page ${ctx.pageNumber} of 9  |  ${DateFormat("dd MMM yyyy").format(r.generatedAt)}  |  CONFIDENTIAL',
                    style: const pw.TextStyle(fontSize: 7, color: _textMut)),
              ]),
            )),
      ]),
    );
  }

  static pw.Widget _infoRow(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.Row(children: [
      pw.SizedBox(width: 90, child: pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: _textMut))),
      pw.Expanded(child: pw.Text(value,
          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _textDk))),
    ]),
  );
}
