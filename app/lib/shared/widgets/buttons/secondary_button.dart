import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';
import '../loaders/coin_pulse_loader.dart';

/// GigCredit Secondary Button
/// Transparent bg with border, hover/focus states
/// Spec: 52px height, 16px radius, 1.5px solid #E2EDE7
class SecondaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final Widget? icon;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
  });

  @override
  State<SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<SecondaryButton> {
  bool _isPressed = false;

  bool get _effectiveDisabled =>
      widget.isDisabled || widget.isLoading || widget.onPressed == null;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: AppSpacing.buttonHeightSecondary,
        decoration: BoxDecoration(
          color: _isPressed
              ? AppColors.greenMuted.withValues(alpha: 0.3)
              : Colors.transparent,
          borderRadius: AppSpacing.buttonBorderRadius,
          border: Border.all(
            color: _isPressed
                ? AppColors.greenBright.withValues(alpha: 0.4)
                : AppColors.borderCard,
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _effectiveDisabled ? null : _handleTap,
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            borderRadius: AppSpacing.buttonBorderRadius,
            splashColor: AppColors.greenMuted.withValues(alpha: 0.3),
            child: Center(
              child: widget.isLoading
                  ? const CoinPulseLoader(
                      color: AppColors.greenPrimary,
                      size: 8.0,
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          widget.icon!,
                          const SizedBox(width: 10),
                        ],
                        Flexible(
                          child: Text(
                            widget.label,
                            textAlign: TextAlign.center,
                            style: AppTypography.labelLarge.copyWith(
                              color: _isPressed
                                  ? AppColors.greenPrimary
                                  : AppColors.textSecondary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onPressed?.call();
  }
}
