// ignore_for_file: avoid_print
/// GigLogger — Live terminal logging for GigCredit pipeline
/// Shows real-time data flow: extraction → validation → state update → scoring
library;

class GigLogger {
  static const _reset = '\x1B[0m';
  static const _bold = '\x1B[1m';
  static const _green = '\x1B[32m';
  static const _cyan = '\x1B[36m';
  static const _yellow = '\x1B[33m';
  static const _red = '\x1B[31m';
  static const _magenta = '\x1B[35m';
  static const _blue = '\x1B[34m';
  static const _white = '\x1B[97m';
  static const _dim = '\x1B[2m';

  static String _ts() {
    final t = DateTime.now();
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    final s = t.second.toString().padLeft(2, '0');
    final ms = t.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }

  // ─── Banners ────────────────────────────────────────────────────────────────

  static void stepBanner(int step, String title) {
    print('');
    print(
        '$_bold$_cyan╔══════════════════════════════════════════════════════════════════╗$_reset');
    print(
        '$_bold$_cyan║  [$_white[GigCredit]$_cyan] STEP $step: $title${' ' * (51 - title.length - step.toString().length)}║$_reset');
    print(
        '$_bold$_cyan╚══════════════════════════════════════════════════════════════════╝$_reset');
  }

  static void sectionHeader(String title) {
    print('');
    print('$_bold$_blue  ── $title $_dim${'─' * (55 - title.length)}$_reset');
  }

  static void divider() {
    print(
        '$_dim  ──────────────────────────────────────────────────────────────$_reset');
  }

  // ─── Log levels ────────────────────────────────────────────────────────────

  static void ok(String msg) {
    print('$_green  ✅ $_reset$_white${_ts()}$_reset  $msg');
  }

  static void warn(String msg) {
    print('$_yellow  ⚠️  $_reset$_white${_ts()}$_reset  $_yellow$msg$_reset');
  }

  static void fail(String msg) {
    print('$_red  ❌ $_reset$_white${_ts()}$_reset  $_red$msg$_reset');
  }

  static void info(String msg) {
    print('$_cyan  ℹ️  $_reset$_white${_ts()}$_reset  $msg');
  }

  static void data(String label, dynamic value) {
    final lbl = label.padRight(24);
    print('$_dim  │$_reset  $_magenta$lbl$_reset : $_white$value$_reset');
  }

  static void check(String label, bool passed, {String? detail}) {
    final icon = passed ? '$_green✅$_reset' : '$_red❌$_reset';
    final lbl = label.padRight(28);
    final det = detail != null ? '  $_dim($detail)$_reset' : '';
    print('  $icon  $lbl$det');
  }

  static void arrow(String from, String to) {
    print('$_cyan  ➜  $from → $_white$to$_reset');
  }

  static void stateUpdate(String provider, String key, dynamic value) {
    print('$_magenta  💾 $provider[$key]$_reset  ←  $_white$value$_reset');
  }

  static void processing(String msg) {
    print('$_yellow  ⚡ $_reset$_white${_ts()}$_reset  $msg');
  }

  static void score(int value, String range) {
    print('');
    print('$_bold$_green  ╔═══════════════════════════════════╗$_reset');
    print(
        '$_bold$_green  ║  GIGCREDIT SCORE : $value${' ' * (15 - value.toString().length)}║$_reset');
    print(
        '$_bold$_green  ║  RANGE           : $range${' ' * (15 - range.length)}║$_reset');
    print('$_bold$_green  ╚═══════════════════════════════════╝$_reset');
  }

  static void cleanup(int count) {
    print(
        '$_yellow  🗑️  CLEANUP  $_reset: $count temp file(s) permanently deleted — PII gone from device');
  }

  static void ocrStart(String docType, String fileType) {
    print('');
    print(
        '$_blue  📷 OCR START  $_reset:  docType=$docType  file=$fileType  engine=${fileType == 'pdf' ? 'SyncfusionPDF' : 'PaddleOCR'}');
  }

  static void ocrField(String field, String value) {
    final f = field.padRight(22);
    print('$_cyan  ├── $f$_reset : $_white$value$_reset');
  }

  static void ocrEnd(String docType, double confidence) {
    print(
        '$_blue  📷 OCR END    $_reset:  docType=$docType  confidence=${(confidence * 100).toStringAsFixed(1)}%');
  }

  static void crossValidation(
      String fieldA, String valA, String fieldB, String valB, bool match) {
    final icon = match ? '$_green✅$_reset' : '$_red❌$_reset';
    print(
        '  $icon  Cross-Check  $_magenta$fieldA$_reset ($valA)  vs  $_magenta$fieldB$_reset ($valB)  →  ${match ? '$_green MATCH$_reset' : '$_red MISMATCH$_reset'}');
  }

  static void pillarScore(String pillar, double raw, int scaled) {
    final bar = ('█' * (scaled ~/ 10)).padRight(10, '░');
    final p = pillar.padRight(20);
    print(
        '  $_cyan$p$_reset  [$_green$bar$_reset]  raw=$_white${raw.toStringAsFixed(3)}$_reset  scaled=$_bold$_white$scaled$_reset');
  }

  static void shapScore(String feature, double impact, bool positive, String description) {
    final color = positive ? _green : _red;
    final sign = positive ? '+' : '';
    final f = feature.padRight(22);
    print('  $color$sign${impact.toStringAsFixed(3)}$_reset  $_cyan$f$_reset : $_dim$description$_reset');
  }

  static void llmSection(String phase, String detail) {
    print('$_magenta  🤖 LLM [$phase]  $_reset: $detail');
  }
}
