import 'package:flutter/material.dart';

/// Токены цвета — см. design/DESIGN.md. Значения не подбираются "на глаз",
/// любое новое место в UI должно ссылаться на один из этих токенов.
class AppColors {
  const AppColors._();

  static const primary = Color(0xFF1F4FFF);
  static const primaryPressed = Color(0xFF1238C9);
  static const primarySoft = Color(0xFFE6EBFF);
  static const onPrimarySecondary = Color(0xFFD6DEFF);

  static const accent = Color(0xFFFFB020);
  static const onAccent = Color(0xFF1A1300);
  static const accentSoft = Color(0xFFFFF1D6);
  static const accentText = Color(0xFF7A4B00);

  static const success = Color(0xFF11652E);
  static const successSoft = Color(0xFFE3F5E8);
  static const error = Color(0xFFE5484D);
  static const errorSoft = Color(0xFFFDE7E8);

  static const bg = Color(0xFFF3F4F7);
  static const surface = Color(0xFFFFFFFF);
  static const sidebar = Color(0xFF0E1526);
  static const text = Color(0xFF0E1526);
  static const textSecondary = Color(0xFF5B6475);
  static const border = Color(0xFFD5DAE4);
  static const divider = Color(0xFFEEF0F4);

  /// Устаревшие имена для обратной совместимости с существующими экранами
  /// (StatusBadge и т.п.), сопоставлены с ближайшими токенами доки.
  static const neutral = textSecondary;
  static const warning = accentText;
  static const danger = error;
}

/// Отступы: 4 / 8 / 12 / 16 / 20 / 24 / 32. Боковой отступ экрана — 20.
class AppSpacing {
  const AppSpacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const screen = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

/// Скругления: 8 (бейджи), 12–14 (кнопки малые, поля), 16 (главные кнопки),
/// 20 (карточки), 24 (крупные карточки).
class AppRadius {
  const AppRadius._();

  static const badge = 8.0;
  static const field = 12.0;
  static const button = 16.0;
  static const card = 20.0;
  static const cardLarge = 24.0;
}

class AppSizes {
  const AppSizes._();

  static const buttonHeight = 56.0;
  static const iconButtonMin = 44.0;
  static const iconButtonMax = 56.0;
  static const tapTargetMin = 48.0;
  static const bottomNavHeight = 84.0;
}

const _fontFamily = 'Onest';

/// Типографика — см. таблицу стилей в design/DESIGN.md.
class AppTextStyles {
  const AppTextStyles._();

  static const display = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: AppColors.text,
  );

  static const headline = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: AppColors.text,
  );

  static const title = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );

  static const route = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );

  static const priceCard = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColors.text,
  );

  static const priceDetail = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 30,
    fontWeight: FontWeight.w800,
    color: AppColors.text,
  );

  static const button = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w700,
  );

  static const body = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
  );

  static const bodyStrong = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );

  static const caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const small = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
  );
}

class AppTheme {
  const AppTheme._();

  // Тёмная тема — после пилота (см. DESIGN.md), поэтому в приложении
  // используется только light() с явным themeMode: ThemeMode.light.
  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.accent,
      onSecondary: AppColors.onAccent,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.text,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bg,
      fontFamily: _fontFamily,
      splashFactory: InkRipple.splashFactory,
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.display,
        headlineLarge: AppTextStyles.headline,
        titleLarge: AppTextStyles.title,
        titleMedium: AppTextStyles.bodyStrong,
        bodyLarge: AppTextStyles.body,
        bodyMedium: AppTextStyles.body,
        bodySmall: AppTextStyles.caption,
        labelLarge: AppTextStyles.button,
        labelSmall: AppTextStyles.small,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.title,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        labelStyle: const TextStyle(fontFamily: _fontFamily, color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primarySoft,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          textStyle: AppTextStyles.button,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed) ? AppColors.primaryPressed : null,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          side: const BorderSide(color: AppColors.border),
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          textStyle: AppTextStyles.button,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary, textStyle: AppTextStyles.button),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: AppSizes.bottomNavHeight,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primarySoft,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => AppTextStyles.small.copyWith(
            color: states.contains(WidgetState.selected) ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
