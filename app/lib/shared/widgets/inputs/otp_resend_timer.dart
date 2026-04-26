import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'dart:async';

class OtpResendTimer extends StatefulWidget {
  final int durationSeconds;
  final VoidCallback onResend;

  const OtpResendTimer({
    super.key,
    this.durationSeconds = 30,
    required this.onResend,
  });

  @override
  State<OtpResendTimer> createState() => _OtpResendTimerState();
}

class _OtpResendTimerState extends State<OtpResendTimer> {
  late int _secondsLeft;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _secondsLeft = widget.durationSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _handleResend() {
    widget.onResend();
    setState(() {
      _startTimer();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_secondsLeft > 0) {
      return Text(
        'Resend OTP in 00:${_secondsLeft.toString().padLeft(2, '0')}',
        style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
      );
    }

    return GestureDetector(
      onTap: _handleResend,
      child: Text(
        'Resend OTP',
        style: AppTypography.labelLarge.copyWith(
          color: AppColors.accentLight,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
