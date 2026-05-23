import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';
import '../loaders/coin_pulse_loader.dart';

/// GigCredit Primary CTA Button
/// Gradient green background with pulse glow shadow
class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final Widget? icon;
  final Widget? suffixIcon;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.suffixIcon,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _isPressed = false;
  bool _glowHigh = false;

  @override
  void initState() {
    super.initState();
    _startGlowCycle();
  }

  void _startGlowCycle() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      setState(() => _glowHigh = true);
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (!mounted) return;
        setState(() => _glowHigh = false);
        _startGlowCycle();
      });
    });
  }

  bool get _effectiveDisabled =>
      widget.isDisabled || widget.isLoading || widget.onPressed == null;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 1800),
        curve: Curves.easeInOut,
        width: double.infinity,
        height: AppSpacing.buttonHeight,
        decoration: BoxDecoration(
          gradient: _effectiveDisabled ? null : AppColors.ctaGradient,
          color: _effectiveDisabled ? AppColors.borderCard : null,
          borderRadius: AppSpacing.buttonBorderRadius,
          boxShadow: _effectiveDisabled
              ? []
              : [
                  BoxShadow(
                    color: AppColors.greenBright.withValues(
                        alpha: _glowHigh ? 0.55 : 0.30),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _effectiveDisabled ? null : _handleTap,
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            borderRadius: AppSpacing.buttonBorderRadius,
            splashColor: Colors.white.withValues(alpha: 0.15),
            highlightColor: Colors.white.withValues(alpha: 0.08),
            child: Center(
              child: widget.isLoading ? _buildLoader() : _buildLabel(),
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

  Widget _buildLoader() => const CoinPulseLoader(color: Colors.white, size: 8.0);

  Widget _buildLabel() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[widget.icon!, const SizedBox(width: 10)],
        Flexible(
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: AppTypography.button.copyWith(
              color: _effectiveDisabled ? AppColors.textMuted : Colors.white,
              letterSpacing: 0.6,
            ),
          ),
        ),
        if (widget.suffixIcon != null) ...[const SizedBox(width: 10), widget.suffixIcon!],
      ],
    );
  }
}
