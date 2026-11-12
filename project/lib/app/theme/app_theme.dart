import 'package:flutter/material.dart';

import 'app_palette.dart';
import 'soul_tokens.dart';

/// Builds the two Soul King themes from [AppPalette] tokens.
///
/// Both themes share the same component themes, shapes and typography. Only
/// the palette values differ. The [ColorScheme] is built explicitly (not from a
/// seed) so every colour is exactly the token that was reviewed. Material 3
/// defaults then give dialogs, menus and snackbars the right colours from the
/// scheme; only the components whose default would not match are overridden.
class AppTheme {
  AppTheme._();

  /// Soul King - Midnight.
  static final ThemeData night = _build(AppPalette.night);

  /// Soul King - Grand Line.
  static final ThemeData day = _build(AppPalette.day);

  static ThemeData _build(AppPalette p) {
    final scheme = ColorScheme(
      brightness: p.brightness,
      primary: p.primary,
      onPrimary: p.onPrimary,
      primaryContainer: p.primaryContainer,
      onPrimaryContainer: p.onPrimaryContainer,
      secondary: p.secondary,
      onSecondary: p.onSecondary,
      secondaryContainer: p.secondaryContainer,
      onSecondaryContainer: p.onSecondaryContainer,
      error: p.error,
      onError: p.onError,
      surface: p.background,
      onSurface: p.onSurface,
      onSurfaceVariant: p.onSurfaceVariant,
      outline: p.outlineStrong,
      outlineVariant: p.outline,
      shadow: Colors.black,
      scrim: p.scrim,
      inverseSurface: p.inverseSurface,
      onInverseSurface: p.onInverseSurface,
      inversePrimary: p.inversePrimary,
      // No tint overlay: surfaces stay exactly the palette colours.
      surfaceTint: Colors.transparent,
      surfaceDim: p.background,
      surfaceBright: p.card,
      surfaceContainerLowest: p.background,
      surfaceContainerLow: p.surface,
      surfaceContainer: p.surface,
      surfaceContainerHigh: p.card,
      surfaceContainerHighest: p.card,
    );

    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      extensions: <ThemeExtension<dynamic>>[
        SoulTokens.fromPalette(p),
      ],
      cardTheme: CardThemeData(
        color: p.surface,
        // Night: flat with a hairline. Day: a soft lift.
        elevation: p.isDark ? 0 : 1,
        shadowColor: p.onSurface.withValues(alpha: 0.25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: p.outline),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.card,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.card,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.card,
        modalBackgroundColor: p.card,
        showDragHandle: true,
        dragHandleColor: p.outlineStrong,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: p.accentText,
        inactiveTrackColor: p.outlineStrong,
        thumbColor: p.accentText,
        overlayColor: p.accentText.withValues(alpha: 0.12),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.accentText,
        linearTrackColor: p.outline,
      ),
    );
  }
}
