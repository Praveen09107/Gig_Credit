import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Premium popup dialogs for step navigation flow.
/// Three types: StepConfirm (green), StepBack (orange), AbandonSession (red).

class StepConfirmPopup {
  static Future<bool> show(BuildContext context, {required int stepNumber}) async {
    final loadingTexts = {
      1: 'Verifying your identity...',
      2: 'Checking Aadhaar & PAN...',
      3: 'Validating bank details...',
      4: 'Processing utility bills...',
      5: 'Verifying work proof...',
      6: 'Checking government schemes...',
      7: 'Validating insurance policies...',
      8: 'Verifying tax records...',
      9: 'Analysing loan history...',
    };

    final isStep9 = stepNumber == 9;
    
    return await _showPremiumPopup(
      context,
      icon: isStep9 ? Icons.insights_rounded : Icons.check_circle_outline_rounded,
      iconGradient: isStep9 ? const [Color(0xFF0D47A1), Color(0xFF42A5F5)] : const [Color(0xFF2E7D32), Color(0xFF66BB6A)],
      title: isStep9 ? 'Generate Score?' : 'Continue to next step?',
      body: isStep9 ? 'Do you want to generate the final credit score?' : 'Your Step $stepNumber data will be verified and saved.',
      confirmLabel: isStep9 ? 'GENERATE SCORE' : 'CONFIRM & CONTINUE',
      cancelLabel: 'CANCEL',
      confirmColor: isStep9 ? const Color(0xFF1565C0) : const Color(0xFF2E7D32),
    ) ?? false;
  }
}

class StepBackPopup {
  static Future<bool> show(BuildContext context, {required int stepNumber}) async {
    return await _showPremiumPopup(
      context,
      icon: Icons.arrow_back_rounded,
      iconGradient: const [Color(0xFFE65100), Color(0xFFFFA726)],
      title: 'Go back to Step ${stepNumber - 1}?',
      body: 'Your progress on this step will not be saved.',
      confirmLabel: 'GO BACK',
      cancelLabel: 'STAY HERE',
      confirmColor: const Color(0xFFE65100),
    ) ?? false;
  }
}

class AbandonSessionPopup {
  static Future<bool> show(BuildContext context) async {
    return await _showPremiumPopup(
      context,
      icon: Icons.warning_amber_rounded,
      iconGradient: const [Color(0xFFC62828), Color(0xFFEF5350)],
      title: 'Cancel scoring process?',
      body: 'All your entered details and verified information from this session will be permanently removed.',
      confirmLabel: 'YES, CANCEL',
      cancelLabel: 'KEEP GOING',
      confirmColor: const Color(0xFFC62828),
      isDestructive: true,
    ) ?? false;
  }
}

Future<bool?> _showPremiumPopup(
  BuildContext context, {
  required IconData icon,
  required List<Color> iconGradient,
  required String title,
  required String body,
  required String confirmLabel,
  required String cancelLabel,
  required Color confirmColor,
  bool isDestructive = false,
}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color(0xA60D1F15),
    transitionDuration: const Duration(milliseconds: 350),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final scaleAnim = Tween<double>(begin: 0.80, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: Curves.elasticOut),
      );
      final fadeAnim = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(
        opacity: fadeAnim,
        child: ScaleTransition(scale: scaleAnim, child: child),
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) {
      return _PopupContent(
        icon: icon,
        iconGradient: iconGradient,
        title: title,
        body: body,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        confirmColor: confirmColor,
        isDestructive: isDestructive,
      );
    },
  );
}

class _PopupContent extends StatelessWidget {
  final IconData icon;
  final List<Color> iconGradient;
  final String title;
  final String body;
  final String confirmLabel;
  final String cancelLabel;
  final Color confirmColor;
  final bool isDestructive;

  const _PopupContent({
    required this.icon,
    required this.iconGradient,
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.confirmColor,
    required this.isDestructive,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon container
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: iconGradient,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: iconGradient.first.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A2E23),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),

                // Body
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7C8F),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),

                // Buttons
                Row(
                  children: [
                    // Cancel
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop(false);
                        },
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            cancelLabel,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6B7C8F),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Confirm
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          Navigator.of(context).pop(true);
                        },
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: confirmColor,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: confirmColor.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            confirmLabel,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-screen loading overlay shown during API verification
class StepLoadingOverlay extends StatelessWidget {
  final String message;
  final bool isVisible;

  const StepLoadingOverlay({
    super.key,
    required this.message,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Container(
      color: const Color(0x99000000),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A2E23),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
