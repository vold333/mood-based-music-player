import 'package:flutter/material.dart';

/// Raw colour tokens for one Soul King theme.
///
/// Night (Soul King) and Day (Grand Line) use exactly the same fields; only the
/// values differ. Screens never read this class directly. They read the
/// resulting [ColorScheme] (`Theme.of(context).colorScheme`) or [SoulTokens]
/// (`context.soul`).
///
/// Contrast (WCAG) was checked for every text/background pair below:
/// body and secondary text, text on primary / secondary / container / error
/// fills, accent text, and the placeholder icon all pass 4.5:1 (3:1 for
/// non-text), in both themes.
@immutable
class AppPalette {
  const AppPalette({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.card,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.accentText,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.error,
    required this.onError,
    required this.outline,
    required this.outlineStrong,
    required this.inverseSurface,
    required this.onInverseSurface,
    required this.inversePrimary,
    required this.scrim,
    required this.parchment,
    required this.gold,
    required this.placeholderSurface,
  });

  final Brightness brightness;

  // Surfaces.
  final Color background; // Scaffold background.
  final Color surface; // Cards and low-lift containers.
  final Color card; // Dialogs, sheets, menus, mini player.

  // Text.
  final Color onSurface;
  final Color onSurfaceVariant;

  // Brand.
  final Color primary; // Fills and large controls (white text on top).
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color accentText; // Brand colour for small text, icons, active tracks.
  final Color secondary; // Ocean accent.
  final Color onSecondary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;

  // State.
  final Color error;
  final Color onError;

  // Lines.
  final Color outline; // Decorative: dividers, hairlines.
  final Color outlineStrong; // Functional: input borders, inactive tracks (3:1+).

  // Snackbars (inverse surfaces).
  final Color inverseSurface;
  final Color onInverseSurface;
  final Color inversePrimary;

  // Overlays and decoration.
  final Color scrim;
  final Color parchment; // Banner accent, never a list surface.
  final Color gold; // Decoration only, never carries text or meaning.
  final Color placeholderSurface; // Behind the "no artwork" placeholder.

  bool get isDark => brightness == Brightness.dark;

  /// Soul King - Midnight: dark ocean, midnight navy, Soul Purple, Ocean Cyan.
  static const AppPalette night = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF0B0F1A),
    surface: Color(0xFF121828),
    card: Color(0xFF1A2236),
    onSurface: Color(0xFFEEF1F8),
    onSurfaceVariant: Color(0xFFA9B4CC),
    primary: Color(0xFF6A2EFF),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF2B1B6E),
    onPrimaryContainer: Color(0xFFD9CCFF),
    accentText: Color(0xFFA98BFF),
    secondary: Color(0xFF00BBD6),
    onSecondary: Color(0xFF00252B),
    secondaryContainer: Color(0xFF0B3A47),
    onSecondaryContainer: Color(0xFFBDF3FF),
    error: Color(0xFFFF6B6B),
    onError: Color(0xFF3B0A0A),
    outline: Color(0xFF2B3552),
    outlineStrong: Color(0xFF7683A8),
    inverseSurface: Color(0xFFDDE3F0),
    onInverseSurface: Color(0xFF0B0F1A),
    inversePrimary: Color(0xFF5A1FE0),
    scrim: Color(0xFF000000),
    parchment: Color(0xFFF4E3C1),
    gold: Color(0xFFF5C542),
    placeholderSurface: Color(0xFF1E1B3F),
  );

  /// Soul King - Grand Line: sunny sky, ocean blues, warm ivory, deep navy text.
  static const AppPalette day = AppPalette(
    brightness: Brightness.light,
    background: Color(0xFFF5F9FF),
    surface: Color(0xFFFFF8E8),
    card: Color(0xFFFFFFFF),
    onSurface: Color(0xFF12354F),
    onSurfaceVariant: Color(0xFF3F6482),
    primary: Color(0xFF6A2EFF),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE6DDFF),
    onPrimaryContainer: Color(0xFF2A0E8F),
    accentText: Color(0xFF5A1FE0),
    secondary: Color(0xFF0B7A9C),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFD3EEF6),
    onSecondaryContainer: Color(0xFF063A4D),
    error: Color(0xFFC62828),
    onError: Color(0xFFFFFFFF),
    outline: Color(0xFFB9CCDC),
    outlineStrong: Color(0xFF5F7C94),
    inverseSurface: Color(0xFF12354F),
    onInverseSurface: Color(0xFFF5F9FF),
    inversePrimary: Color(0xFFB9A2FF),
    scrim: Color(0xFF0B2540),
    parchment: Color(0xFFF4E3C1),
    gold: Color(0xFFD9A441),
    placeholderSurface: Color(0xFFE4DDFB),
  );
}
