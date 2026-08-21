import 'package:flutter/material.dart';

/// The four colour domains of the calculator, plus the neutral ramp.
///
/// Each input owns a hue -- amount is blue, people green, tip orange, total
/// gold -- and that mapping is information, not decoration. It is carried by a
/// rail and a tinted label rather than a translucent fill over the whole card,
/// which is what used to muddy the text contrast.
///
/// Registered as a [ThemeExtension] so widgets read it through
/// `Theme.of(context).extension<AppColors>()!` and both brightnesses resolve
/// from one place.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color paper;
  final Color surface;
  final Color sunk;
  final Color ink;
  final Color ink2;
  final Color ink3;
  final Color line;
  final Color line2;

  final Color amount;
  final Color people;
  final Color tip;
  final Color total;

  final Color amountBg;
  final Color peopleBg;
  final Color tipBg;
  final Color totalBg;

  const AppColors({
    required this.paper,
    required this.surface,
    required this.sunk,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.line,
    required this.line2,
    required this.amount,
    required this.people,
    required this.tip,
    required this.total,
    required this.amountBg,
    required this.peopleBg,
    required this.tipBg,
    required this.totalBg,
  });

  static const AppColors light = AppColors(
    paper: Color(0xFFF4F5F3),
    surface: Color(0xFFFFFFFF),
    sunk: Color(0xFFECEEEA),
    ink: Color(0xFF1A1F1C),
    ink2: Color(0xFF5A625C),
    ink3: Color(0xFF8A928B),
    line: Color(0xFFE0E2DD),
    line2: Color(0xFFCFD3CC),
    amount: Color(0xFF2F6FED),
    people: Color(0xFF1E9E6A),
    tip: Color(0xFFE0632C),
    total: Color(0xFFA8861B),
    amountBg: Color(0xFFEAF0FE),
    peopleBg: Color(0xFFE6F5EE),
    tipBg: Color(0xFFFDEDE4),
    totalBg: Color(0xFFF8F1DC),
  );

  /// Not an inversion of [light]: the tints drop to roughly 8% luminance and
  /// the domain hues are lifted so they stay legible on a dark ground.
  static const AppColors dark = AppColors(
    paper: Color(0xFF121513),
    surface: Color(0xFF1B1F1C),
    sunk: Color(0xFF232824),
    ink: Color(0xFFEDEFEA),
    ink2: Color(0xFF9BA39C),
    ink3: Color(0xFF6F776F),
    line: Color(0xFF2C312D),
    line2: Color(0xFF3A403B),
    amount: Color(0xFF6E9BFF),
    people: Color(0xFF46C68F),
    tip: Color(0xFFFF8A56),
    total: Color(0xFFE8C453),
    amountBg: Color(0xFF1B2434),
    peopleBg: Color(0xFF16291F),
    tipBg: Color(0xFF2E2018),
    totalBg: Color(0xFF2B2616),
  );

  @override
  AppColors copyWith({
    Color? paper,
    Color? surface,
    Color? sunk,
    Color? ink,
    Color? ink2,
    Color? ink3,
    Color? line,
    Color? line2,
    Color? amount,
    Color? people,
    Color? tip,
    Color? total,
    Color? amountBg,
    Color? peopleBg,
    Color? tipBg,
    Color? totalBg,
  }) {
    return AppColors(
      paper: paper ?? this.paper,
      surface: surface ?? this.surface,
      sunk: sunk ?? this.sunk,
      ink: ink ?? this.ink,
      ink2: ink2 ?? this.ink2,
      ink3: ink3 ?? this.ink3,
      line: line ?? this.line,
      line2: line2 ?? this.line2,
      amount: amount ?? this.amount,
      people: people ?? this.people,
      tip: tip ?? this.tip,
      total: total ?? this.total,
      amountBg: amountBg ?? this.amountBg,
      peopleBg: peopleBg ?? this.peopleBg,
      tipBg: tipBg ?? this.tipBg,
      totalBg: totalBg ?? this.totalBg,
    );
  }

  @override
  AppColors lerp(covariant ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      paper: Color.lerp(paper, other.paper, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      sunk: Color.lerp(sunk, other.sunk, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      ink2: Color.lerp(ink2, other.ink2, t)!,
      ink3: Color.lerp(ink3, other.ink3, t)!,
      line: Color.lerp(line, other.line, t)!,
      line2: Color.lerp(line2, other.line2, t)!,
      amount: Color.lerp(amount, other.amount, t)!,
      people: Color.lerp(people, other.people, t)!,
      tip: Color.lerp(tip, other.tip, t)!,
      total: Color.lerp(total, other.total, t)!,
      amountBg: Color.lerp(amountBg, other.amountBg, t)!,
      peopleBg: Color.lerp(peopleBg, other.peopleBg, t)!,
      tipBg: Color.lerp(tipBg, other.tipBg, t)!,
      totalBg: Color.lerp(totalBg, other.totalBg, t)!,
    );
  }
}

/// Shorthand for the domain palette at this point in the tree.
extension AppColorsContext on BuildContext {
  /// Falls back to the palette matching the ambient brightness when the
  /// extension is absent -- a widget shown under a plain [ThemeData] should
  /// render in the wrong-ish shade, not crash on a null assertion.
  AppColors get colors {
    final theme = Theme.of(this);
    return theme.extension<AppColors>() ??
        (theme.brightness == Brightness.dark ? AppColors.dark : AppColors.light);
  }
}
