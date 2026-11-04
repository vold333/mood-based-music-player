
// ignore_for_file: unnecessary_underscores

import 'dart:io';

import 'package:flutter/material.dart';

class ArtworkImage extends StatelessWidget {
  final String? artworkPath;
  final double size;
  final double borderRadius;

  const ArtworkImage({
    super.key,
    required this.artworkPath,
    this.size = 56,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final path = artworkPath;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: size,
        height: size,
        child: path != null && path.isNotEmpty
            ? Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.deepPurple.withValues(alpha: 0.2),
      child: const Center(
        child: Icon(
          Icons.music_note_rounded,
          size: 30,
          color: Colors.deepPurpleAccent,
        ),
      ),
    );
  }
}
