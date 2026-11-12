import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Soul King design tokens that a [ColorScheme] has no slot for.
///
/// Registered on both themes through `ThemeData.extensions`, so any widget can
/// read them with `context.soul` and never needs to know which theme is active.
@immutable
class SoulTokens extends ThemeExtension<SoulTokens> {
  const SoulTokens({
    required this.parchment,
    required this.gold,
    required this.accentText,
    required this.placeholderSurface,
  });

  factory SoulTokens.fromPalette(AppPalette palette) {
    return SoulTokens(
      parchment: palette.parchment,
      gold: palette.gold,
      accentText: palette.accentText,
      placeholderSurface: palette.placeholderSurface,
    );
  }

  /// Banner accent. Never used as a list surface.
  final Color parchment;

  /// Decoration only. Never carries text or meaning.
  final Color gold;

  /// Brand colour that is safe for small text and icons on this theme.
  final Color accentText;

  /// Background of the "no artwork" placeholder.
  final Color placeholderSurface;

  @override
  SoulTokens copyWith({
    Color? parchment,
    Color? gold,
    Color? accentText,
    Color? placeholderSurface,
  }) {
    return SoulTokens(
      parchment: parchment ?? this.parchment,
      gold: gold ?? this.gold,
      accentText: accentText ?? this.accentText,
      placeholderSurface: placeholderSurface ?? this.placeholderSurface,
    );
  }

  @override
  SoulTokens lerp(ThemeExtension<SoulTokens>? other, double t) {
    if (other is! SoulTokens) return this;

    return SoulTokens(
      parchment: Color.lerp(parchment, other.parchment, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      accentText: Color.lerp(accentText, other.accentText, t)!,
      placeholderSurface:
          Color.lerp(placeholderSurface, other.placeholderSurface, t)!,
    );
  }
}

final SoulTokens _fallbackTokens = SoulTokens.fromPalette(AppPalette.night);

extension SoulThemeContext on BuildContext {
  /// Soul King tokens for the active theme.
  ///
  /// Falls back to the Night values when the widget tree has no Soul King
  /// theme (for example a plain MaterialApp in a widget test).
  SoulTokens get soul =>
      Theme.of(this).extension<SoulTokens>() ?? _fallbackTokens;
}
