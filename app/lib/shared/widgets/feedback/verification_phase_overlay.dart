import 'package:flutter/material.dart';

/// GAP 2 FIX: Verification phase overlay mixin
///
/// Provides a visual "Verifying..." overlay during the cross-verification
/// and backend API call phase. Steps show this between the user pressing
/// "Continue" and the validation completing.
///
/// Usage: Mix into any step screen's State and call showVerificationPhase()
/// in the _submit() method. Phases auto-cycle through messages.
mixin VerificationPhaseMixin<T extends StatefulWidget> on State<T> {
  OverlayEntry? _verificationOverlay;
  String _verificationPhase = 'Validating inputs...';

  /// Show verification overlay with cycling phase messages
  void showVerificationPhase() {
    _verificationOverlay?.remove();
    _verificationPhase = 'Validating inputs...';

    _verificationOverlay = OverlayEntry(
      builder: (ctx) => _VerificationOverlayWidget(
        phase: _verificationPhase,
      ),
    );

    Overlay.of(context).insert(_verificationOverlay!);

    // Cycle through phases
    _cyclePhases();
  }

  Future<void> _cyclePhases() async {
    final phases = [
      'Validating inputs...',
      'Cross-checking identity...',
      'Matching bank transactions...',
      'Contacting verification server...',
      'Applying consistency rules...',
      'Finalizing verification...',
    ];

    for (int i = 0; i < phases.length; i++) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (_verificationOverlay == null) return; // Already dismissed
      _verificationPhase = phases[i];
      _verificationOverlay?.markNeedsBuild();
    }
  }

  /// Dismiss the verification overlay
  void dismissVerificationPhase() {
    _verificationOverlay?.remove();
    _verificationOverlay = null;
  }

  @override
  void dispose() {
    _verificationOverlay?.remove();
    _verificationOverlay = null;
    super.dispose();
  }
}

class _VerificationOverlayWidget extends StatelessWidget {
  final String phase;

  const _VerificationOverlayWidget({required this.phase});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 48),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F2E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF00D4B4).withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00D4B4).withValues(alpha: 0.15),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pulsing verification icon
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: const Color(0xFF00D4B4),
                  backgroundColor: const Color(0xFF00D4B4).withValues(alpha: 0.15),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Verifying...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                phase,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF00D4B4).withValues(alpha: 0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Please wait — do not close the app',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
