
import 'package:flutter/material.dart';

import '../../app/theme/soul_tokens.dart';
import '../../data/models/song.dart';
import 'artwork_image.dart';

/// "3:05" style duration for a song length in seconds.
String formatSongDuration(int seconds) {
  final duration = Duration(seconds: seconds);

  return '${duration.inMinutes}:'
      '${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}';
}

String _spokenDuration(int seconds) {
  final duration = Duration(seconds: seconds);
  final minutes = duration.inMinutes;
  final secs = duration.inSeconds.remainder(60);

  final minutesText = minutes == 1 ? '1 minute' : '$minutes minutes';
  final secondsText = secs == 1 ? '1 second' : '$secs seconds';

  if (minutes == 0) return secondsText;
  if (secs == 0) return minutesText;

  return '$minutesText $secondsText';
}

/// A song row: the song's original embedded artwork, title, artist, category
/// and duration. Tapping plays the song.
///
/// It deliberately has no favourite button, overflow menu or queue controls.
class SongTile extends StatelessWidget {
  const SongTile({
    super.key,
    required this.song,
    required this.onTap,
    this.showCategory = true,
    this.onLongPress,
    this.selectionMode = false,
    this.selected = false,
  });

  final Song song;
  final VoidCallback onTap;
  final bool showCategory;
  final VoidCallback? onLongPress;
  final bool selectionMode;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    final artist = song.artist ?? 'Unknown Artist';
    final category = song.categoryName ?? 'Uncategorized';

    return Semantics(
      button: true,
      excludeSemantics: true,
      label: '${song.title}, by $artist, '
          '${showCategory ? 'in $category, ' : ''}'
          '${_spokenDuration(song.duration)}',
      onTap: onTap,
      child: ListTile(
        onTap: onTap,
        onLongPress: onLongPress,
        selected: selected,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selectionMode)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  selected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: selected ? scheme.primary : scheme.outline,
                  size: 22,
                ),
              ),
            ArtworkImage(
          artworkPath: song.artworkPath,
          size: 52,
          borderRadius: 10,
        ),
          ],
        ),
        title: Text(
          song.title,
          maxLines: scale > 1.3 ? 2 : 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (showCategory)
              Text(
                category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: context.soul.accentText,
                ),
              ),
          ],
        ),
        trailing: Text(
          formatSongDuration(song.duration),
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}