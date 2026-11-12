import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'artwork_image.dart';

/// Hero tag shared by the Mini Player and Now Playing artwork.
///
/// Use it only on those two widgets, never on list rows: two Heroes with the
/// same tag in one route throw an error.
const String nowPlayingArtworkHeroTag = 'now-playing-artwork';

/// The current song's original artwork, wrapped so it glides between the Mini
/// Player and Now Playing.
class NowPlayingArtworkHero extends StatelessWidget {
  const NowPlayingArtworkHero({
    super.key,
    required this.artworkPath,
    required this.size,
    required this.borderRadius,
    this.fit = BoxFit.cover,
  });

  final String? artworkPath;
  final double size;
  final double borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: nowPlayingArtworkHeroTag,
      flightShuttleBuilder: _buildFlight,
      child: ArtworkImage(
        artworkPath: artworkPath,
        size: size,
        borderRadius: borderRadius,
        fit: fit,
      ),
    );
  }

  /// Builds the artwork that flies between two heroes.
  ///
  /// Flutter uses the destination hero's builder (the Now Playing hero when
  /// pushing, the Mini Player hero when popping), so nothing here may depend
  /// on which hero owns the builder. Everything is read from the two endpoint
  /// heroes instead.
  static Widget _buildFlight(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    final fromArtwork = (fromHeroContext.widget as Hero).child;
    final toArtwork = (toHeroContext.widget as Hero).child;

    if (fromArtwork is! ArtworkImage || toArtwork is! ArtworkImage) {
      return toArtwork;
    }

    // The larger endpoint is the Now Playing artwork. The flight copies its
    // fit (BoxFit.contain, so non-square artwork is never cropped) and its
    // size, which is also its image decode size, so the flight reuses the
    // image Now Playing has already decoded instead of decoding another.
    final fullArtwork =
        fromArtwork.size >= toArtwork.size ? fromArtwork : toArtwork;

    final isPush = flightDirection == HeroFlightDirection.push;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        // `animation` is the route animation: 0 -> 1 when pushing, 1 -> 0 when
        // popping. The flight always travels from the "from" hero to the "to"
        // hero, so progress is flipped when popping. Interpolating between the
        // endpoints' own radii keeps the corners correct in both directions
        // (compact -> full on push, full -> compact on pop) and for flights
        // between two Mini Players (no change).
        final progress =
            (isPush ? animation.value : 1.0 - animation.value).clamp(0.0, 1.0);
        final radius = lerpDouble(
          fromArtwork.borderRadius,
          toArtwork.borderRadius,
          progress,
        )!;

        // Same colour as the Mini Player card and the Now Playing frame, so
        // letterbox bars around non-square artwork never show through.
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: ArtworkImage(
            artworkPath: fullArtwork.artworkPath,
            size: fullArtwork.size,
            borderRadius: radius,
            fit: fullArtwork.fit,
          ),
        );
      },
    );
  }
}