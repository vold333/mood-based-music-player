
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';

import '../../app/theme/soul_tokens.dart';
import '../../features/player/playback_handler.dart';
import '../../features/player/now_playing_screen.dart';
import 'artwork_hero.dart';

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
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
            child: Material(
              color: scheme.surfaceContainerHighest,
              elevation: 3,
              shadowColor: scheme.shadow.withValues(alpha: 0.18),
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: scheme.outlineVariant),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 68,
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NowPlayingScreen(),
                        ),
                      );
                    },
                    child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                                  NowPlayingArtworkHero(
                                    artworkPath:
                                        mediaItem.artUri?.scheme == 'file'
                                ? mediaItem.artUri!.toFilePath()
                                : null,
                                    size: 48,
                                    borderRadius: 10,
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
                                            fontWeight: FontWeight.w600,
                                  ),
                                ),
                                        const SizedBox(height: 2),
                                Text(
                                  mediaItem.artist ?? 'Unknown Artist',
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
                      onPressed: isPlaying
                          ? handler.pause
                          : handler.play,
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
                  onPressed: handler.skipToNext,
                  icon: const Icon(Icons.skip_next_rounded),
                ),

                        const SizedBox(width: 4),
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

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    final track = Theme.of(context).colorScheme.outlineVariant;
    final fill = context.soul.accentText;

    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox(
          height: 3,
          child: Stack(
            children: [
              Positioned.fill(child: ColoredBox(color: track)),
              Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: fraction,
                  heightFactor: 1,
                  child: ColoredBox(color: fill),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}