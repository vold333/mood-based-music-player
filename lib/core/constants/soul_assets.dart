import 'dart:math';

import '../../data/models/category.dart';

/// Central asset paths for the Grand Line (Day) visual system.
abstract final class SoulAssets {
  static const logo = 'assets/images/branding/soul_king_logo.png';
  static const splash = 'assets/images/splash/grand_line_splash.png';
  static const homeHeader = 'assets/images/home/grand_line_header.png';

  static const categoryBanner =
      'assets/images/categories/category_parchment_banner.png';
  static const categoryBottomIsland =
      'assets/images/categories/category_bottom_island.png';

  static const emptyLibrary =
      'assets/images/empty_states/empty_library.png';
  static const emptyCategory =
      'assets/images/empty_states/empty_catgory.png';
  static const noSearchResults =
      'assets/images/empty_states/no_search_results.png';

  static const scanningMascot =
      'assets/images/scanning/brook_scanning_mascot.png';

  static const oceanWave = 'assets/images/categories/ocean_wave.png';
  static const uncategorized =
      'assets/images/decorative/marine_emblem.png';

  /// The category illustration pool. The category ID seeds the selection so
  /// an illustration remains stable across rebuilds, renames and app restarts.
  static const categoryIllustrations = <String>[
    'assets/images/categories/straw_hat.png',
    'assets/images/categories/transponder_snail.png',
    'assets/images/categories/devil_fruit.png',
    'assets/images/categories/treasure_chest.png',
    'assets/images/categories/electric_guitar.png',
    'assets/images/decorative/whitebeard_emblem.png',
    'assets/images/categories/sword.png',
    'assets/images/categories/ocean_wave.png',
  ];

  static String artworkForCategory(Category category) {
    if (category.isDefault) return uncategorized;

    final id = category.id ?? 0;
    final index = Random(id).nextInt(categoryIllustrations.length);
    return categoryIllustrations[index];
  }
}
