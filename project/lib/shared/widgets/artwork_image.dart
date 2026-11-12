
// ignore_for_file: unnecessary_underscores

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/soul_tokens.dart';

class ArtworkImage extends StatelessWidget {
  final String? artworkPath;
  final double size;
  final double borderRadius;

  /// How the artwork fills its square. Thumbnails use [BoxFit.cover]; Now
  /// Playing uses [BoxFit.contain] so non-square artwork is never cropped.
  final BoxFit fit;

  const ArtworkImage({
    super.key,
    required this.artworkPath,
    this.size = 56,
    this.borderRadius = 12,
    this.fit = BoxFit.cover,
  });

  // Embedded artwork is often 1000-3000 px. Decoding it at full size for a
  // 50 px thumbnail wastes memory and thrashes the image cache, so the image
  // is decoded near its display size instead. The file on disk is never
  // changed. The oversample factor keeps the shorter edge sharp for
  // non-square artwork up to 16:9 when it is shown with BoxFit.cover.
  static const double _decodeOversample = 1.8;
  static const int _maxDecodeWidth = 1600;

  @override
  Widget build(BuildContext context) {
    final path = artworkPath;
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final decodeWidth = math.min(
      (size * pixelRatio * _decodeOversample).ceil(),
      _maxDecodeWidth,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: size,
        height: size,
        child: path != null && path.isNotEmpty
            ? Image.file(
                File(path),
                fit: fit,
                cacheWidth: decodeWidth,
                gaplessPlayback: true,
                errorBuilder: (context, error, stackTrace) =>
                    _placeholder(context),
              )
            : _placeholder(context),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    final soul = context.soul;

    return Container(
      color: soul.placeholderSurface,
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          size: 30,
          color: soul.accentText,
        ),
      ),
    );
  }
}
