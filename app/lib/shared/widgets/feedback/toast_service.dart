import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_toast.dart';
import 'toast_types.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// ToastService — Global toast manager using Overlay
/// Only 1 toast visible at a time. New toast cancels current.
/// ─────────────────────────────────────────────────────────────────────────────

final toastServiceProvider = Provider<ToastService>((ref) => ToastService());

class ToastService {
  OverlayEntry? _currentEntry;
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Show toast by ID (from registry)
  void showById(String toastId) {
    final data = toastRegistry[toastId];
    if (data == null) {
      debugPrint('[ToastService] Unknown toast ID: $toastId');
      return;
    }
    show(data);
  }

  /// Show custom toast data
  void show(ToastData data) {
    _removeCurrentToast();

    final context = navigatorKey.currentContext;
    if (context == null) {
      debugPrint('[ToastService] No context available for toast');
      return;
    }

    final overlay = Overlay.of(context);

    _currentEntry = OverlayEntry(
      builder: (_) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Material(
          type: MaterialType.transparency,
          child: AppToast(
            data: data,
            onDismiss: _removeCurrentToast,
          ),
        ),
      ),
    );

    overlay.insert(_currentEntry!);
  }

  /// Show a quick success toast with custom title/subtitle
  void success(String title, {String? subtitle}) {
    show(ToastData(
      id: 'custom_success',
      type: ToastType.success,
      emoji: '✅',
      title: title,
      subtitle: subtitle,
    ));
  }

  /// Show a quick error toast with custom title/subtitle
  void error(String title, {String? subtitle}) {
    show(ToastData(
      id: 'custom_error',
      type: ToastType.error,
      emoji: '❌',
      title: title,
      subtitle: subtitle,
    ));
  }

  /// Show a quick warning toast
  void warning(String title, {String? subtitle}) {
    show(ToastData(
      id: 'custom_warning',
      type: ToastType.warning,
      emoji: '⚠️',
      title: title,
      subtitle: subtitle,
    ));
  }

  /// Show a quick info toast
  void info(String title, {String? subtitle}) {
    show(ToastData(
      id: 'custom_info',
      type: ToastType.info,
      emoji: 'ℹ️',
      title: title,
      subtitle: subtitle,
    ));
  }

  /// Show a processing toast (stays until replaced)
  void processing(String title, {String? subtitle}) {
    show(ToastData(
      id: 'custom_processing',
      type: ToastType.processing,
      emoji: '⏳',
      title: title,
      subtitle: subtitle,
    ));
  }

  /// Dismiss current toast
  void dismiss() => _removeCurrentToast();

  void _removeCurrentToast() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

/// Global singleton for non-Riverpod access
final globalToastService = ToastService();

/// ─────────────────────────────────────────────────────────────────────────────
/// ToastOverlay — wrap MaterialApp to enable global toast display
/// ─────────────────────────────────────────────────────────────────────────────
class ToastOverlay extends StatelessWidget {
  final Widget child;

  const ToastOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child;
}
