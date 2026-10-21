import 'package:flutter/material.dart';

// ======================================================
// DESIGN SYSTEM: semua warna & gaya dikumpulkan di satu tempat
// supaya tampilan konsisten di semua halaman.
// ======================================================
class AppColors {
  static const bg = Color(0xFF0E1014); // latar halaman
  static const surface = Color(0xFF171A21); // kartu
  static const surfaceHigh = Color(0xFF1F232C); // input, chip
  static const border = Color(0xFF2A2F3A);
  static const accent = Color(0xFFF5A623); // amber khas PUBG
  static const accentDark = Color(0xFFD9731A);
  static const onAccent = Color(0xFF1A1200);
  static const success = Color(0xFF3DDC97);
  static const danger = Color(0xFFFF5C6C);
  static const textPrimary = Color(0xFFF2F4F8);
  static const textSecondary = Color(0xFF9AA3B2);

  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD36B), accentDark],
  );
}

class AppTheme {
  static const double radius = 16;

  // Dekorasi kartu standar (dipakai berulang)
  static BoxDecoration kartu({bool selected = false, Color? warna}) {
    return BoxDecoration(
      color: warna ?? AppColors.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: selected ? AppColors.accent : AppColors.border,
        width: selected ? 1.6 : 1,
      ),
    );
  }

  // Dekorasi input standar (dipakai TextField Player ID, pencarian, nama)
  static InputDecoration input({
    required String hint,
    Widget? prefix,
    Widget? suffix,
    String? error,
  }) {
    OutlineInputBorder garis(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textSecondary),
      prefixIcon: prefix,
      suffixIcon: suffix,
      errorText: error,
      filled: true,
      fillColor: AppColors.surfaceHigh,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: garis(AppColors.border),
      focusedBorder: garis(AppColors.accent, 1.6),
      errorBorder: garis(AppColors.danger),
      focusedErrorBorder: garis(AppColors.danger, 1.6),
      border: garis(AppColors.border),
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.accent,
      onPrimary: AppColors.onAccent,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.danger,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bg,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.accent.withValues(alpha: 0.18),
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final aktif = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: aktif ? FontWeight.w700 : FontWeight.w500,
            color: aktif ? AppColors.accent : AppColors.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final aktif = states.contains(WidgetState.selected);
          return IconThemeData(
            color: aktif ? AppColors.accent : AppColors.textSecondary,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.onAccent,
          disabledBackgroundColor: AppColors.surfaceHigh,
          disabledForegroundColor: AppColors.textSecondary,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceHigh,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        actionTextColor: AppColors.accent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? AppColors.onAccent
                : AppColors.textSecondary),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? AppColors.accent
                : AppColors.surfaceHigh),
        trackOutlineColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? Colors.transparent
                : AppColors.border),
      ),
      dividerColor: AppColors.border,
    );
  }
}
