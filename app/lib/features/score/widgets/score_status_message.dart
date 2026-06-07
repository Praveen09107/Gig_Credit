import 'package:flutter/material.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';

/// Score Status Message — shows pipeline steps with realistic timing.
class ScoreStatusMessage extends StatefulWidget {
  const ScoreStatusMessage({super.key});

  @override
  State<ScoreStatusMessage> createState() => _ScoreStatusMessageState();
}

class _ScoreStatusMessageState extends State<ScoreStatusMessage> {
  static const List<(String, int)> _steps = [
    ('Analysing your identity documents...', 2000),
    ('Extracting income & bank patterns...', 2500),
    ('Running 8-pillar ML scoring models...', 3000),
    ('Applying isotonic calibration...', 2000),
    ('Computing SHAP explainability...', 2500),
    ('Generating causal chains & actions...', 2000),
    ('Calling AI language model (Groq)...', 4000),
    ('Storing your score securely...', 1500),
    ('Almost ready — finalising report...', 2000),
  ];

  int _currentIndex = 0;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _runSteps();
    _tickElapsed();
  }

  void _runSteps() async {
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(Duration(milliseconds: _steps[i].$2));
      if (!mounted) return;
      setState(() {
        _currentIndex = (i + 1) < _steps.length ? i + 1 : i;
      });
    }
  }

  void _tickElapsed() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _elapsedSeconds++);
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentIndex];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                      begin: const Offset(0, 0.2), end: Offset.zero)
                  .animate(anim),
              child: child,
            ),
          ),
          child: Text(
            step.$1,
            key: ValueKey(_currentIndex),
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 10),
        // Step progress dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_steps.length, (i) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: i == _currentIndex ? 16 : 6,
              height: 4,
              decoration: BoxDecoration(
                color: i <= _currentIndex
                    ? AppColors.greenPrimary
                    : AppColors.borderCard,
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          '${_elapsedSeconds}s · Step ${_currentIndex + 1}/${_steps.length}',
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
