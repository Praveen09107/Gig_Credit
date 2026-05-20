import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../shared/theme/app_colors.dart';
import '../shared/theme/app_typography.dart';
import '../shared/theme/app_spacing.dart';
import 'app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GigCreditApp extends ConsumerWidget {
  const GigCreditApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'GigCredit',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: _buildTheme(),
    );
  }

  ThemeData _buildTheme() {
    // ── LIGHT theme base (was dark) ──────────────────────────────────
    final base = ThemeData.light();

    return base.copyWith(
      // ── Core colors ───────────────────────────────────────────────
      scaffoldBackgroundColor: AppColors.bgScreen,
      primaryColor: AppColors.greenPrimary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.greenPrimary,
        primaryContainer: AppColors.greenMuted,
        secondary: AppColors.greenBright,
        secondaryContainer: AppColors.greenMuted,
        surface: AppColors.bgCard,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        onError: Colors.white,
      ),

      // ── Typography ────────────────────────────────────────────────
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: AppTypography.displayLarge,
        displayMedium: AppTypography.displayMedium,
        displaySmall: AppTypography.displaySmall,
        headlineLarge: AppTypography.headlineLarge,
        headlineMedium: AppTypography.headlineMedium,
        headlineSmall: AppTypography.headlineSmall,
        titleLarge: AppTypography.titleLarge,
        titleMedium: AppTypography.titleMedium,
        titleSmall: AppTypography.titleSmall,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.labelLarge,
        labelMedium: AppTypography.labelMedium,
        labelSmall: AppTypography.labelSmall,
      ),

      // ── App Bar ───────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgCard,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.greenPrimary, size: 24),
        titleTextStyle: AppTypography.titleMedium.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 17,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),

      // ── Input Fields ──────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: const OutlineInputBorder(
          borderRadius: AppSpacing.inputBorderRadius,
          borderSide: BorderSide(color: AppColors.borderCard),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppSpacing.inputBorderRadius,
          borderSide: BorderSide(color: AppColors.borderCard, width: 1.5),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppSpacing.inputBorderRadius,
          borderSide: BorderSide(color: AppColors.greenPrimary, width: 2.0),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppSpacing.inputBorderRadius,
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppSpacing.inputBorderRadius,
          borderSide: BorderSide(color: AppColors.error, width: 2.0),
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
        errorStyle: AppTypography.labelSmall.copyWith(color: AppColors.error, fontSize: 12),
        floatingLabelStyle: AppTypography.labelMedium.copyWith(color: AppColors.greenPrimary),
      ),

      // ── Elevated Buttons ──────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.greenPrimary,
          foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(borderRadius: AppSpacing.buttonBorderRadius),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: AppTypography.button,
          elevation: 0,
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
        ),
      ),

      // ── Outlined Buttons ──────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          side: const BorderSide(color: AppColors.borderCard, width: 1.5),
          shape: const RoundedRectangleBorder(borderRadius: AppSpacing.buttonBorderRadius),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600),
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeightSecondary),
        ),
      ),

      // ── Text Buttons ──────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.greenPrimary,
          textStyle: AppTypography.labelLarge.copyWith(color: AppColors.greenPrimary),
        ),
      ),

      // ── Bottom Navigation Bar ─────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgCard,
        selectedItemColor: AppColors.greenPrimary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
        selectedLabelStyle: AppTypography.labelSmall.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.greenPrimary,
        ),
        unselectedLabelStyle: AppTypography.labelSmall.copyWith(
          color: AppColors.textMuted,
        ),
      ),

      // ── Cards ─────────────────────────────────────────────────────
      cardTheme: const CardThemeData(
        color: AppColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.cardBorderRadius),
        margin: EdgeInsets.zero,
      ),

      // ── Dividers ──────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.borderCard,
        thickness: 1,
        space: 0,
      ),

      // ── Dialogs ───────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.bgCard,
        shape: const RoundedRectangleBorder(borderRadius: AppSpacing.cardBorderRadius),
        titleTextStyle: AppTypography.headlineMedium,
        contentTextStyle: AppTypography.bodyMedium,
      ),

      // ── Bottom Sheets ─────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.sheetBorderRadius),
        elevation: 16,
        dragHandleColor: AppColors.borderCard,
        dragHandleSize: Size(40, 4),
        showDragHandle: true,
      ),

      // ── Snackbar ──────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.bgCard,
        contentTextStyle: AppTypography.bodyMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
      ),

      // ── Chips ─────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.greenMuted,
        labelStyle: AppTypography.chip.copyWith(color: AppColors.greenPrimary),
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.pillBorderRadius,
        ),
        side: BorderSide(color: AppColors.greenBright.withValues(alpha: 0.25)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // ── Progress Indicators ───────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.greenPrimary,
        linearTrackColor: AppColors.greenMuted,
        circularTrackColor: AppColors.greenMuted,
      ),

      // ── Floating Action Button ────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.greenPrimary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // ── Tab Bar ───────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.greenPrimary,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: AppTypography.labelLarge,
        unselectedLabelStyle: AppTypography.labelMedium,
        indicator: const BoxDecoration(
          borderRadius: AppSpacing.pillBorderRadius,
          color: AppColors.greenMuted,
        ),
      ),
    );
  }
}
