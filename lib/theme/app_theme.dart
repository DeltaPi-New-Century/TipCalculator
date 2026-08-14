import 'package:flutter/material.dart';
import 'package:tip_calculator/theme/app_colors.dart';

/// Builds both brightnesses from the same [AppColors] token set.
///
/// Every colour a widget uses comes from the extension or from the scheme
/// derived here -- nothing hardcodes a literal, so the dark theme cannot drift
/// out of sync with the light one.
class AppTheme {
  const AppTheme._();

  /// Monospace for figures. Money in a calculator should line up in columns,
  /// which also means [FontFeature] tabular figures wherever digits appear.
  static const List<String> monoFallback = <String>[
    'SF Mono',
    'Menlo',
    'Consolas',
    'Roboto Mono',
    'monospace',
  ];

  static const TextStyle mono = TextStyle(
    fontFamilyFallback: monoFallback,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static ThemeData light() => _build(AppColors.light, Brightness.light);
  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(final AppColors colors, final Brightness brightness) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: colors.amount,
          brightness: brightness,
        ).copyWith(
          surface: colors.surface,
          onSurface: colors.ink,
          outline: colors.line2,
          outlineVariant: colors.line,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.paper,
      extensions: <ThemeExtension<dynamic>>[colors],
      dividerTheme: DividerThemeData(color: colors.line, space: 1, thickness: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.paper,
        foregroundColor: colors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: colors.ink,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: colors.line),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.ink,
        contentTextStyle: TextStyle(color: colors.surface, fontSize: 14),
        actionTextColor: colors.tip,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.sunk,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.line2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.line2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.amount, width: 2),
        ),
        labelStyle: TextStyle(color: colors.ink2, fontSize: 14),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: colors.amount),
      ),
      iconTheme: IconThemeData(color: colors.ink2),
      listTileTheme: ListTileThemeData(iconColor: colors.ink2),
      textTheme: Typography.material2021(
        platform: TargetPlatform.android,
      ).black.apply(bodyColor: colors.ink, displayColor: colors.ink),
    );
  }

  /// Uppercase micro-label used above every value in the UI.
  static TextStyle fieldLabel(final AppColors colors) => TextStyle(
    fontFamilyFallback: monoFallback,
    fontSize: 10,
    letterSpacing: 1.3,
    fontWeight: FontWeight.w600,
    color: colors.ink2,
  );

  /// Figures. [size] and [weight] vary; tabular alignment never does.
  static TextStyle figure({
    required final double size,
    required final Color color,
    final FontWeight weight = FontWeight.w600,
    final double letterSpacing = -0.5,
  }) => TextStyle(
    fontFamilyFallback: monoFallback,
    fontFeatures: const [FontFeature.tabularFigures()],
    fontSize: size,
    fontWeight: weight,
    letterSpacing: letterSpacing,
    color: color,
  );
}
