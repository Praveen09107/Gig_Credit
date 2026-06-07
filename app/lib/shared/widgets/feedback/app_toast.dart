import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// GigCredit Toast Notification System
/// Usage: AppToast.success(context, 'Message here');
enum ToastType { success, error, warning, info }

class AppToast {
  static void success(BuildContext context, String message, {String? subtitle}) {
    _show(context, message, subtitle: subtitle, type: ToastType.success);
  }

  static void error(BuildContext context, String message, {String? subtitle}) {
    _show(context, message, subtitle: subtitle, type: ToastType.error);
  }

  static void warning(BuildContext context, String message, {String? subtitle}) {
    _show(context, message, subtitle: subtitle, type: ToastType.warning);
  }

  static void info(BuildContext context, String message, {String? subtitle}) {
    _show(context, message, subtitle: subtitle, type: ToastType.info);
  }

  static void _show(BuildContext context, String message,
      {String? subtitle, required ToastType type}) {
    final overlay = Overlay.of(context);

    final Color borderColor;
    final IconData icon;
    final Color iconColor;

    switch (type) {
      case ToastType.success:
        borderColor = const Color(0xFF4CAF50);
        icon = Icons.check_circle_rounded;
        iconColor = const Color(0xFF4CAF50);
        break;
      case ToastType.error:
        borderColor = const Color(0xFFE53935);
        icon = Icons.error_rounded;
        iconColor = const Color(0xFFE53935);
        break;
      case ToastType.warning:
        borderColor = const Color(0xFFFFA726);
        icon = Icons.warning_rounded;
        iconColor = const Color(0xFFFFA726);
        break;
      case ToastType.info:
        borderColor = const Color(0xFF42A5F5);
        icon = Icons.info_rounded;
        iconColor = const Color(0xFF42A5F5);
        break;
    }

    late OverlayEntry entry;
    bool _removed = false;

    void safeRemove() {
      if (!_removed && entry.mounted) {
        _removed = true;
        entry.remove();
      }
    }

    entry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        subtitle: subtitle,
        borderColor: borderColor,
        icon: icon,
        iconColor: iconColor,
        onDismiss: safeRemove,
      ),
    );

    overlay.insert(entry);

    // Auto-dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), safeRemove);
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final String? subtitle;
  final Color borderColor;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    this.subtitle,
    required this.borderColor,
    required this.icon,
    required this.iconColor,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();

    // Start dismiss animation after 2.5s
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 60,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onVerticalDragEnd: (_) => widget.onDismiss(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border(
                    left: BorderSide(color: widget.borderColor, width: 4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(widget.icon, color: widget.iconColor, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.message,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A2E23),
                            ),
                          ),
                          if (widget.subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.subtitle!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onDismiss,
                      child: const Icon(Icons.close, size: 18, color: Color(0xFFBDBDBD)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
