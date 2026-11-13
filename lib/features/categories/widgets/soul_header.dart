import 'package:flutter/material.dart';

import '../../../app/theme/glass_tokens.dart';
import '../../../core/constants/soul_assets.dart';
import '../../../shared/widgets/glass_surface.dart';

/// Grand Line scenic header used by the Home screen.
///
/// The Going Merry artwork is the Home screen's visual identity and is shown
/// untouched, apart from a very light shade at the bottom edge. The Soul King
/// name card is rendered by the SliverAppBar title, separately from this
/// background, so both can scale independently. A single frosted chip carries
/// the library summary, and a thin rim of light closes the scene.
class SoulHeader extends StatelessWidget {
  const SoulHeader({
    super.key,
    required this.subtitle,
    this.showTagline = true,
  });

  /// Library summary, for example "9 categories · 120 songs".
  final String subtitle;

  /// Hides the summary chip at large text sizes, where the header is too short.
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final glass = context.glass;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(32),
        bottomRight: Radius.circular(32),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            SoulAssets.homeHeader,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (_, __, ___) => DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [glass.skyCyan, glass.oceanBlue],
                ),
              ),
            ),
          ),
          // Barely-there shade so the chip and the sea edge stay calm.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x000B2540),
                  Color(0x080B2540),
                  Color(0x300B2540),
                ],
                stops: [0, 0.6, 1],
              ),
            ),
          ),
          // Rim of light along the bottom edge, like sun on the horizon.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  border: Border(
                    bottom: BorderSide(color: glass.borderSoft, width: 1.5),
                  ),
                ),
              ),
            ),
          ),
          if (showTagline)
            Positioned(
              left: 16,
              bottom: 18,
              right: 16,
              child: Align(
                alignment: Alignment.bottomLeft,
                child: GlassSurface(
                  radius: 20,
                  blur: true,
                  blurSigma: 12,
                  shadow: false,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.sailing_rounded,
                        size: 16,
                        color: scheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
