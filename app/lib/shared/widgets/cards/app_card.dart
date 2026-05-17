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

class _AppCardState extends State<AppCard> with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _glowController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _glowController.reset();
      }
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = true);
      _glowController.forward(from: 0.0);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
      widget.onTap!();
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = _isPressed ? 0.97 : 1.0;

    Widget cardContent = Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: AppSpacing.cardBorderRadius,
        border: widget.hasGradientBorder
            ? null
            : Border.all(color: AppColors.borderCard),
        boxShadow: _isPressed
            ? [BoxShadow(color: AppColors.greenPrimary.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))]
            : AppColors.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.accentTopColor != null)
            Container(
              height: widget.accentTopWidth,
              color: widget.accentTopColor,
            ),
          Padding(
            padding: widget.padding,
            child: widget.child,
          ),
        ],
      ),
    );

    Widget card;
    if (widget.onTap != null) {
      card = GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Moving border glow
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) {
                    if (!_glowController.isAnimating) return const SizedBox.shrink();
                    
                    final angle = _glowController.value * 3.14159 * 2;
                    final opacity = _glowController.value < 0.5 
                        ? _glowController.value * 2.0 
                        : (1.0 - _glowController.value) * 2.0;

                    return Opacity(
                      opacity: opacity * 0.8,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: SweepGradient(
                            center: Alignment.center,
                            startAngle: 0.0,
                            endAngle: 3.14159 * 2,
                            transform: GradientRotation(angle),
                            colors: [
                              Colors.transparent,
                              AppColors.greenBright.withValues(alpha: 0.8),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.25, 0.5],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Main card content (slightly smaller to show border glow)
              Padding(
                padding: const EdgeInsets.all(2.0),
                child: cardContent,
              ),
            ],
          ),
        ),
      );
    } else {
      card = cardContent;
    }

    if (widget.hasGradientBorder && widget.onTap == null) {
      return Container(
        decoration: const BoxDecoration(
          borderRadius: AppSpacing.cardBorderRadius,
          gradient: AppColors.ctaGradient,
        ),
        padding: const EdgeInsets.all(1.5),
        child: card,
      );
    }

    return card;
  }
}
