import '../../data/models/category.dart';

/// Central asset paths for the Grand Line (Day) visual system.
abstract final class SoulAssets {
  static const logo = 'assets/images/branding/soul_king_logo.png';
  static const nameCard = 'assets/images/branding/soul_king_name_card.png';
  static const splash = 'assets/images/splash/grand_line_splash.png';
  // Approved large Going Merry scenery, with open sky for the separate name card.
  static const homeHeader = 'assets/images/home/grand_line_header2.png';

  static const emptyLibrary =
      'assets/images/empty_states/empty_library.png';
  static const emptyCategory =
      'assets/images/empty_states/empty_category.png';
  static const noSearchResults =
      'assets/images/empty_states/no_search_results.png';

  static const scanningMascot =
      'assets/images/scanning/brook_scanning_mascot.png';

  static const oceanWave = 'assets/images/categories/ocean_wave.png';
  static const uncategorized =
      'assets/images/decorative/marine_emblem.png';

  /// The category illustration pool. Each category stores its assigned index
  /// in SQLite, so illustrations follow a stable cycle without random repeats.
  static const categoryIllustrations = <String>[
    // 1–4: Iconic One Piece objects
    'assets/images/categories/straw_hat.png',
    'assets/images/categories/devil_fruit.png',
    'assets/images/categories/transponder_snail.png',
    'assets/images/categories/whitebeard_emblem.png',

    // 5–8: Characters and their signatures
    'assets/images/categories/ace_hat.png',
    'assets/images/categories/zoro_katanas.png',
    'assets/images/categories/news_coo.png',

    // 9–11: Music and adventure
    'assets/images/categories/electric_guitar.png',
    'assets/images/categories/ocean_wave.png',
    'assets/images/categories/sword.png',

    // 12–14: Iconic crew and character artwork
    'assets/images/categories/chopper_hat.png',
    'assets/images/categories/treasure_chest.png',
    'assets/images/categories/zoro_wanted_poster.png',
    'assets/images/categories/karoo_duck.png',
  ];

  static String artworkForCategory(Category category) {
    if (category.isDefault) return uncategorized;

    final fallbackId = category.id ?? 2;
    final storedIndex = category.illustrationIndex ?? (fallbackId - 2);
    final index =
        ((storedIndex % categoryIllustrations.length) +
            categoryIllustrations.length) %
        categoryIllustrations.length;
    return categoryIllustrations[index];
  }
}
