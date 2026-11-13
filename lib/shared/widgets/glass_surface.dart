import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../app/theme/glass_tokens.dart';

/// The one glass surface used across Soul King.
///
/// Layers, bottom to top: a soft shadow, the (optionally blurred) backdrop, a
/// translucent fill, a faint reflection from the top-left corner and a thin
/// bright rim. Everything is decoration, so the child keeps its own semantics.
///
/// Performance: [blur] is off by default. Use it for a handful of floating
/// surfaces only (header chip, Mini Player, Now Playing controls). Rows and
/// grid cards use the stronger, almost-opaque fill, which looks like glass
/// over the page backdrop without a per-frame blur.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.radius = 22,
    this.blur = false,
    this.blurSigma = 14,
    this.strong = true,
    this.shadow = true,
    this.padding,
    this.rim,
  });

  final Widget child;
  final double radius;

  /// Blurs whatever is behind the surface.
  final bool blur;
  final double blurSigma;

  /// Uses the stronger fill. Turn it off only for large, text-free areas.
  final bool strong;

  /// Draws the soft drop shadow.
  final bool shadow;

  final EdgeInsetsGeometry? padding;

  /// Overrides the rim colour (for example a gold hairline).
  final Color? rim;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final shape = BorderRadius.circular(radius);

    Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        color: strong ? glass.fillStrong : glass.fill,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [glass.sheen, glass.sheen.withValues(alpha: 0)],
          stops: const [0, 0.55],
        ),
        border: Border.all(color: rim ?? glass.border, width: 1),
      ),
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );

    if (blur) {
      surface = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: surface,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: glass.shadow,
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: ClipRRect(borderRadius: shape, child: surface),
    );
  }
}

/// Page backdrop: a sky-to-foam gradient with one soft cyan glow, like light
/// on open water. Cheap (two static gradients) and shared by every screen.
class GrandLineBackdrop extends StatelessWidget {
  const GrandLineBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return ExcludeSemantics(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [glass.backdropTop, glass.backdropBottom],
              ),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.9, -0.55),
                  radius: 0.9,
                  colors: [
                    glass.glow.withValues(alpha: 0.18),
                    glass.glow.withValues(alpha: 0),
                  ],
                ),
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}
