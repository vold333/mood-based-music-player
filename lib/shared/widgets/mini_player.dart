
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';

import '../../app/theme/glass_tokens.dart';
import '../../app/theme/soul_tokens.dart';
import '../../features/player/playback_handler.dart';
import '../../features/player/now_playing_screen.dart';
import 'artwork_hero.dart';
import 'glass_surface.dart';

/// Grand Line Glass Mini Player: a floating glass pill with the song's
/// original artwork, title, artist, play/pause, next and a slim progress line.
///
/// No blur: it sits in the Scaffold's bottom slot, so there is no scrolling
/// content behind it to frost. The strong glass fill keeps it light and cheap.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final handler = playbackHandlerInstance;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return StreamBuilder<MediaItem?>(
      stream: handler.mediaItem,
      builder: (context, mediaSnapshot) {
        final mediaItem = mediaSnapshot.data;

        if (mediaItem == null) {
          return const SizedBox.shrink();
        }

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
            child: GlassSurface(
              radius: 26,
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 66,
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(26),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const NowPlayingScreen(),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: Row(
                                  children: [
                                    NowPlayingArtworkHero(
                                      artworkPath:
                                          mediaItem.artUri?.scheme == 'file'
                                              ? mediaItem.artUri!.toFilePath()
                                              : null,
                                      size: 48,
                                      borderRadius: 14,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            mediaItem.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.titleSmall
                                                ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: scheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            mediaItem.artist ??
                                                'Unknown Artist',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: scheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          StreamBuilder<PlaybackState>(
                            stream: handler.playbackState,
                            builder: (context, playbackSnapshot) {
                              final isPlaying =
                                  playbackSnapshot.data?.playing ?? false;

                              return IconButton.filled(
                                tooltip: isPlaying ? 'Pause' : 'Play',
                                onPressed:
                                    isPlaying ? handler.pause : handler.play,
                                icon: Icon(
                                  isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                ),
                              );
                            },
                          ),
                          IconButton(
                            tooltip: 'Next',
                            color: scheme.onSurface,
                            onPressed: handler.skipToNext,
                            icon: const Icon(Icons.skip_next_rounded),
                          ),
                          const SizedBox(width: 6),
                        ],
                      ),
                    ),
                    _MiniProgress(
                      handler: handler,
                      duration: mediaItem.duration,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Thin playback progress line under the Mini Player.
///
/// Every screen in the navigation stack has its own Mini Player. Screens that
/// are covered by another route have their tickers disabled, so they skip the
/// position subscription and only the visible Mini Player updates.
class _MiniProgress extends StatelessWidget {
  const _MiniProgress({
    required this.handler,
    required this.duration,
  });

  final PlaybackHandler handler;
  final Duration? duration;

  double _fraction(Duration position) {
    final total = duration?.inMilliseconds ?? 0;

    if (total <= 0) return 0;

    return (position.inMilliseconds / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final active = TickerMode.valuesOf(context).enabled;

    if (!active) {
      return _ProgressBar(fraction: _fraction(handler.currentPosition));
    }

    return StreamBuilder<Duration>(
      stream: handler.positionStream,
      initialData: handler.currentPosition,
      builder: (context, snapshot) {
        return _ProgressBar(
          fraction: _fraction(snapshot.data ?? Duration.zero),
        );
      },
    );
  }
}

/// A rounded progress line inset from the pill's edges. The fill runs from
/// ocean blue into Soul Purple, like a current picking up speed.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    final track = Theme.of(context).colorScheme.outlineVariant;
    final glass = context.glass;
    final accent = context.soul.accentText;

    return ExcludeSemantics(
      child: RepaintBoundary(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 9),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 4,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ColoredBox(color: track.withValues(alpha: 0.7)),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: fraction,
                      heightFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [glass.oceanBlue, accent],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
