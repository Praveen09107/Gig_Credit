import 'dart:async';
import 'package:flutter/material.dart';
import 'toast_types.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AppToast — Premium animated toast notification widget
/// Spec: fixed top, white card, colored left border, emoji icon, progress bar
/// ─────────────────────────────────────────────────────────────────────────────
class AppToast extends StatefulWidget {
  final ToastData data;
  final VoidCallback onDismiss;

  const AppToast({super.key, required this.data, required this.onDismiss});

  @override
  State<AppToast> createState() => _AppToastState();
}

class _AppToastState extends State<AppToast> with TickerProviderStateMixin {
  late AnimationController _enterController;
  late AnimationController _progressController;
  late AnimationController _exitController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  Timer? _autoDismissTimer;
  bool _isExiting = false;

  ToastStyle get _style => toastStyles[widget.data.type]!;

  @override
  void initState() {
    super.initState();

    // Enter animation: slide down + fade in + scale
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _enterController,
      curve: const Cubic(0.34, 1.56, 0.64, 1),
    ));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _enterController, curve: Curves.easeOut),
    );
    _scaleAnim = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _enterController, curve: const Cubic(0.34, 1.56, 0.64, 1)),
    );

    // Exit animation
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    // Progress bar animation
    final autoDismiss = _style.autoDismiss;
    _progressController = AnimationController(
      vsync: this,
      duration: autoDismiss > Duration.zero ? autoDismiss : const Duration(seconds: 30),
    );

    _enterController.forward();
    _progressController.forward();

    // Auto-dismiss timer
    if (autoDismiss > Duration.zero) {
      _autoDismissTimer = Timer(autoDismiss, _dismiss);
    }
  }

  void _dismiss() {
    if (_isExiting) return;
    _isExiting = true;
    _autoDismissTimer?.cancel();
    _exitController.forward().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _enterController.dispose();
    _progressController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = _style;
    final isProcessing = widget.data.type == ToastType.processing;

    return AnimatedBuilder(
      animation: Listenable.merge([_enterController, _exitController]),
      builder: (context, child) {
        final exitFade = 1.0 - _exitController.value;
        final exitSlide = _exitController.value * -20;

        return Transform.translate(
          offset: Offset(0, exitSlide),
          child: Opacity(
            opacity: (_fadeAnim.value * exitFade).clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: SlideTransition(
        position: _slideAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: GestureDetector(
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity != null && details.primaryVelocity! < -300) {
                _dismiss();
              }
            },
            child: Container(
              margin: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: style.borderColour, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 28,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Main content row
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        // Colored left border
                        Container(width: 4, color: style.colour),
                        const SizedBox(width: 12),

                        // Icon circle
                        Container(
                          width: 38,
                          height: 38,
                          margin: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: style.iconBg,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: isProcessing
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation(style.colour),
                                    ),
                                  )
                                : Text(
                                    widget.data.emoji,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Text column
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.data.title,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Color(0xFF0D1F15),
                                  ),
                                ),
                                if (widget.data.subtitle != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.data.subtitle!,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w400,
                                      fontSize: 12,
                                      color: Color(0xFF4A6B57),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        // Dismiss button
                        GestureDetector(
                          onTap: _dismiss,
                          child: Container(
                            width: 36,
                            height: 36,
                            margin: const EdgeInsets.only(right: 8),
                            alignment: Alignment.center,
                            child: const Text(
                              '✕',
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF8FA89B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Progress bar at bottom
                  if (!isProcessing)
                    AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, _) {
                        return Container(
                          height: 3,
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: 1.0 - _progressController.value,
                            child: Container(
                              decoration: BoxDecoration(
                                color: style.colour.withValues(alpha: 0.35),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
