import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Grand Line Glass tokens: the translucent surfaces, borders, sheens and
/// ocean colours shared by every screen.
///
/// Registered next to [SoulTokens] on both themes, so widgets read them with
/// `context.glass` and never need to know which theme is active.
///
/// Glass is used sparingly: strong, almost-opaque fills for rows and cards
/// (cheap, no blur) and real blur only for a few floating surfaces.
@immutable
class GlassTokens extends ThemeExtension<GlassTokens> {
  const GlassTokens({
    required this.backdropTop,
    required this.backdropBottom,
    required this.glow,
    required this.chrome,
    required this.fill,
    required this.fillStrong,
    required this.border,
    required this.borderSoft,
    required this.sheen,
    required this.shadow,
    required this.skyCyan,
    required this.oceanBlue,
    required this.deepNavy,
    required this.goldHairline,
  });

  factory GlassTokens.fromPalette(AppPalette p) {
    if (p.isDark) {
      return const GlassTokens(
        backdropTop: Color(0xFF0E1B33),
        backdropBottom: Color(0xFF0B0F1A),
        glow: Color(0xFF00BBD6),
        chrome: Color(0xFF111C33),
        fill: Color(0x991A2236),
        fillStrong: Color(0xCC1A2236),
        border: Color(0x33FFFFFF),
        borderSoft: Color(0x1FFFFFFF),
        sheen: Color(0x26FFFFFF),
        shadow: Color(0x66000000),
        skyCyan: Color(0xFF4FC3E8),
        oceanBlue: Color(0xFF1E88C8),
        deepNavy: Color(0xFF0B2540),
        goldHairline: Color(0x80F5C542),
      );
    }

    return const GlassTokens(
      // Sky mist at the top, fading to a paler sea-foam white.
      backdropTop: Color(0xFFDCEFFB),
      backdropBottom: Color(0xFFF4FAFE),
      glow: Color(0xFF4FC3E8),
      // Solid colour of the collapsed Home app bar.
      chrome: Color(0xFFDCEFFB),
      fill: Color(0x99FFFFFF),
      fillStrong: Color(0xC7FFFFFF),
      border: Color(0xE6FFFFFF),
      borderSoft: Color(0x99FFFFFF),
      sheen: Color(0x8CFFFFFF),
      shadow: Color(0x240B3A5E),
      skyCyan: Color(0xFF4FC3E8),
      oceanBlue: Color(0xFF1E88C8),
      deepNavy: Color(0xFF0B2A45),
      goldHairline: Color(0xB3D9A441),
    );
  }

  /// Page backdrop gradient (top to bottom).
  final Color backdropTop;
  final Color backdropBottom;

  /// Soft cyan light that sits in the corner of the backdrop.
  final Color glow;

  /// Solid colour of app bars once their scenery has scrolled away.
  final Color chrome;

  /// Standard glass fill and the stronger fill used under text.
  final Color fill;
  final Color fillStrong;

  /// Glass edge. [border] is the bright rim, [borderSoft] the quiet one.
  final Color border;
  final Color borderSoft;

  /// Reflection at the top-left of a glass surface.
  final Color sheen;

  /// Soft drop shadow colour.
  final Color shadow;

  /// Ocean colours for illustration glows and small accents.
  final Color skyCyan;
  final Color oceanBlue;
  final Color deepNavy;

  /// Thin gold detail. Decoration only, never carries text or meaning.
  final Color goldHairline;

  @override
  GlassTokens copyWith({
    Color? backdropTop,
    Color? backdropBottom,
    Color? glow,
    Color? chrome,
    Color? fill,
    Color? fillStrong,
    Color? border,
    Color? borderSoft,
    Color? sheen,
    Color? shadow,
    Color? skyCyan,
    Color? oceanBlue,
    Color? deepNavy,
    Color? goldHairline,
  }) {
    return GlassTokens(
      backdropTop: backdropTop ?? this.backdropTop,
      backdropBottom: backdropBottom ?? this.backdropBottom,
      glow: glow ?? this.glow,
      chrome: chrome ?? this.chrome,
      fill: fill ?? this.fill,
      fillStrong: fillStrong ?? this.fillStrong,
      border: border ?? this.border,
      borderSoft: borderSoft ?? this.borderSoft,
      sheen: sheen ?? this.sheen,
      shadow: shadow ?? this.shadow,
      skyCyan: skyCyan ?? this.skyCyan,
      oceanBlue: oceanBlue ?? this.oceanBlue,
      deepNavy: deepNavy ?? this.deepNavy,
      goldHairline: goldHairline ?? this.goldHairline,
    );
  }

  @override
  GlassTokens lerp(ThemeExtension<GlassTokens>? other, double t) {
    if (other is! GlassTokens) return this;

    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;

    return GlassTokens(
      backdropTop: mix(backdropTop, other.backdropTop),
      backdropBottom: mix(backdropBottom, other.backdropBottom),
      glow: mix(glow, other.glow),
      chrome: mix(chrome, other.chrome),
      fill: mix(fill, other.fill),
      fillStrong: mix(fillStrong, other.fillStrong),
      border: mix(border, other.border),
      borderSoft: mix(borderSoft, other.borderSoft),
      sheen: mix(sheen, other.sheen),
      shadow: mix(shadow, other.shadow),
      skyCyan: mix(skyCyan, other.skyCyan),
      oceanBlue: mix(oceanBlue, other.oceanBlue),
      deepNavy: mix(deepNavy, other.deepNavy),
      goldHairline: mix(goldHairline, other.goldHairline),
    );
  }
}

final GlassTokens _fallbackGlass = GlassTokens.fromPalette(AppPalette.day);

extension GlassThemeContext on BuildContext {
  /// Grand Line Glass tokens for the active theme.
  GlassTokens get glass =>
      Theme.of(this).extension<GlassTokens>() ?? _fallbackGlass;
}
