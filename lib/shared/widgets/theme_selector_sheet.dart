import 'package:flutter/material.dart';

import '../../app/theme/soul_tokens.dart';
import '../../app/theme/theme_controller.dart';

/// Theme selector. Only Grand Line Day is currently available.
///
/// A choice applies and is saved immediately, and the sheet stays open so the
/// themes can be compared live.
class ThemeSelectorSheet extends StatelessWidget {
  const ThemeSelectorSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (context) => const ThemeSelectorSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: ListenableBuilder(
        listenable: themeController,
        builder: (context, _) {
          final current = themeController.mode;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
                child: Text('Theme', style: theme.textTheme.titleLarge),
              ),
              // Temporarily disabled while the Grand Line Day Theme is the
              // active design target. Keep this option for the Midnight return.
              // _ThemeOptionTile(
              //   mode: ThemeMode.dark,
              //   icon: Icons.dark_mode_rounded,
              //   title: 'Night – Soul King',
              //   subtitle: 'Dark ocean, midnight navy and Soul Purple',
              //   selected: current == ThemeMode.dark,
              // ),
              _ThemeOptionTile(
                mode: ThemeMode.light,
                icon: Icons.light_mode_rounded,
                title: 'Day – Grand Line',
                subtitle: 'Sunny sky, ocean blue and warm ivory',
                selected: current == ThemeMode.light,
              ),
              // System Default is also paused so the OS cannot switch the app
              // back to the unfinished Night experience.
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  const _ThemeOptionTile({
    required this.mode,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
  });

  final ThemeMode mode;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final accent = context.soul.accentText;

    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: selected ? const Icon(Icons.check_circle_rounded) : null,
      // `selected` also exposes the state to screen readers. The accent token
      // keeps selected text and icons readable on both themes.
      selected: selected,
      selectedColor: accent,
      selectedTileColor: accent.withValues(alpha: 0.10),
      onTap: () => themeController.setMode(mode),
    );
  }
}