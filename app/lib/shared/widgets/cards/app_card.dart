import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// GigCredit Universal Card
/// White bg, green-tinted shadow, 20px radius, 1px border
/// Supports tap, accent top border, and gradient border variants
class AppCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool hasGradientBorder;
  final Color? accentTopColor;
  final double? accentTopWidth;

  const AppCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardInsets,
    this.onTap,
    this.hasGradientBorder = false,
    this.accentTopColor,
    this.accentTopWidth = 4.0,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (widget.onTap != null) setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
      widget.onTap!();
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    Widget cardContent = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: AppSpacing.cardBorderRadius,
        border: widget.hasGradientBorder
            ? Border.all(color: AppColors.greenBright.withValues(alpha: 0.50), width: 1.5)
            : Border.all(
                color: _isPressed
                    ? AppColors.greenPrimary.withValues(alpha: 0.40)
                    : AppColors.borderCard,
              ),
        boxShadow: _isPressed
            ? [BoxShadow(color: AppColors.greenPrimary.withValues(alpha: 0.12), blurRadius: 6, offset: const Offset(0, 2))]
            : AppColors.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.accentTopColor != null)
            Container(height: widget.accentTopWidth, color: widget.accentTopColor),
          Padding(padding: widget.padding, child: widget.child),
        ],
      ),
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
