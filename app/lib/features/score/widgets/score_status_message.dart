import 'package:flutter/material.dart';
import '../../../shared/theme/app_typography.dart';

/// Score Status Message — cycling text during score generation
/// Shows on green background so uses white text
class ScoreStatusMessage extends StatefulWidget {
  const ScoreStatusMessage({super.key});

  @override
  State<ScoreStatusMessage> createState() => _ScoreStatusMessageState();
}

class _ScoreStatusMessageState extends State<ScoreStatusMessage> {
  static const List<String> _messages = [
    'Analysing your identity documents...',
    'Processing bank statement patterns...',
    'Calculating gig income stability...',
    'Applying privacy-preserving algorithms...',
    'Running AI credit model (7 pillars)...',
    'Generating your personalised score...',
  ];

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _cycle();
  }

  void _cycle() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 2500));
      if (!mounted) return false;
      setState(() {
        _currentIndex = (_currentIndex + 1) % _messages.length;
      });
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Text(
        _messages[_currentIndex],
        key: ValueKey(_currentIndex),
        style: AppTypography.bodyMedium.copyWith(
          color: Colors.white.withValues(alpha: 0.75),
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
