import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';

/// LLM Explanation Card with Typewriter Animation
/// 
/// Displays the AI-generated plain-language explanation with a
/// character-by-character typewriter effect, as specified in
/// COMP_20_LLM_REPORT_PIPELINE.md and DEV_B_AGENT_IMPLEMENTATION_GUIDE.md Step 9.
///
/// Features:
///   - Character-by-character text reveal with blinking cursor
///   - "AI-Powered Analysis" header with gradient icon
///   - Suggestions list that fades in after explanation completes
///   - Language badge showing the response language
class LlmExplanationCard extends StatefulWidget {
  final String explanation;
  final List<String> suggestions;
  final String language;
  final Duration charDelay;

  const LlmExplanationCard({
    super.key,
    required this.explanation,
    this.suggestions = const [],
    this.language = 'English',
    this.charDelay = const Duration(milliseconds: 18),
  });

  @override
  State<LlmExplanationCard> createState() => _LlmExplanationCardState();
}

class _LlmExplanationCardState extends State<LlmExplanationCard> {
  String _displayedText = '';
  int _charIndex = 0;
  Timer? _timer;
  bool _isTypingComplete = false;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTyping() {
    _timer = Timer.periodic(widget.charDelay, (timer) {
      if (_charIndex < widget.explanation.length) {
        setState(() {
          _charIndex++;
          _displayedText = widget.explanation.substring(0, _charIndex);
        });
      } else {
        timer.cancel();
        setState(() => _isTypingComplete = true);
        // Show suggestions after a brief pause
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) setState(() => _showSuggestions = true);
        });
      }
    });
  }

  /// Skip typewriter animation — show full text immediately
  void _skipAnimation() {
    _timer?.cancel();
    setState(() {
      _displayedText = widget.explanation;
      _charIndex = widget.explanation.length;
      _isTypingComplete = true;
      _showSuggestions = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2A2A4A),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              gradient: LinearGradient(
                colors: [
                  AppColors.accent.withOpacity(0.15),
                  AppColors.card,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accent,
                        AppColors.highlight,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI-Powered Analysis',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Powered by LLaMA 3 • ${widget.language}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // Language badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.language,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Typewriter Text ──
          GestureDetector(
            onTap: _isTypingComplete ? null : _skipAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    height: 1.6,
                    fontFamily: 'Inter',
                  ),
                  children: [
                    TextSpan(text: _displayedText),
                    // Blinking cursor during typing
                    if (!_isTypingComplete)
                      WidgetSpan(
                        child: _BlinkingCursor(),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ── "Tap to skip" hint during typing ──
          if (!_isTypingComplete)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Text(
                'Tap to skip animation',
                style: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.5),
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          // ── Suggestions Section ──
          if (_showSuggestions && widget.suggestions.isNotEmpty) ...[
            const Divider(color: Color(0xFF2A2A4A), height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, color: AppColors.warning, size: 16),
                      const SizedBox(width: 6),
                      const Text(
                        'Suggestions to Improve',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...widget.suggestions.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 20, height: 20,
                            margin: const EdgeInsets.only(right: 10, top: 1),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                '${entry.key + 1}',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate()
                        .fadeIn(delay: Duration(milliseconds: 200 * entry.key), duration: 400.ms)
                        .slideX(begin: 0.05, end: 0);
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }
}

/// Blinking cursor widget for the typewriter effect
class _BlinkingCursor extends StatefulWidget {
  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 2,
        height: 16,
        margin: const EdgeInsets.only(left: 1),
        color: AppColors.accent,
      ),
    );
  }
}
