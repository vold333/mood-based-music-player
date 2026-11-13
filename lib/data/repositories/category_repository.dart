
import 'package:sqflite/sqflite.dart';

import '../../database/database_helper.dart';
import '../models/category.dart';

class CategoryRepository {
  // Keep this in sync with SoulAssets.categoryIllustrations.length.
  static const int _illustrationCycleLength = 14;

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Get all categories.
  Future<List<Category>> getAllCategories() async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'categories',
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return result.map((map) => Category.fromMap(map)).toList();
  }

  // Number of songs in each category, keyed by category ID. Read-only.
  // Categories without songs are absent from the map.
  Future<Map<int, int>> getCategorySongCounts() async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery(
      'SELECT category_id, COUNT(*) AS song_count '
      'FROM songs GROUP BY category_id',
    );

    return {
      for (final row in result)
        row['category_id'] as int: row['song_count'] as int,
    };
  }

  // Get Uncategorized category ID.
  Future<int> getUncategorizedId() async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'categories',
      columns: ['id'],
      where: 'is_default = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (result.isEmpty) {
      throw StateError('Uncategorized category not found.');
    }

    return result.first['id'] as int;
  }

  // Find an existing category or create one from an embedded genre.
  Future<int> getOrCreateGenreCategory(String genre) async {
    final normalizedGenre = genre.trim().replaceAll(RegExp(r'\s+'), ' ');

    if (normalizedGenre.isEmpty) {
      return getUncategorizedId();
    }

    final db = await _databaseHelper.database;

    return db.transaction((txn) async {
      final existing = await txn.query(
        'categories',
        columns: ['id'],
        where: 'name = ?',
        whereArgs: [normalizedGenre],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        return existing.first['id'] as int;
      }

      return _insertCategory(
        txn,
        name: normalizedGenre,
        source: 'genre',
      );
    });
  }

  // Create a category manually.
  Future<int> createCategory(String name) async {
    final normalizedName = name.trim().replaceAll(RegExp(r'\s+'), ' ');

    if (normalizedName.isEmpty) {
      throw ArgumentError('Category name cannot be empty.');
    }

    if (normalizedName.toLowerCase() == 'uncategorized') {
      throw ArgumentError('Uncategorized is a reserved category.');
    }

    final db = await _databaseHelper.database;

    return db.transaction((txn) async {
      return _insertCategory(
        txn,
        name: normalizedName,
        source: 'manual',
      );
    });
  }

  // Insert a category and persist its place in the illustration cycle.
  // Fill unused positions first; once all eight are occupied, wrap to the
  // beginning of the cycle. This also handles categories deleted later.
  Future<int> _insertCategory(
    Transaction txn, {
    required String name,
    required String source,
  }) async {
    final id = await txn.insert('categories', {
      'name': name,
      'is_default': 0,
      'source': source,
    });

    final existing = await txn.query(
      'categories',
      columns: ['illustration_index'],
      where: 'is_default = ? AND id != ?',
      whereArgs: [0, id],
    );
    final usedIndices = existing
        .map((row) => row['illustration_index'] as int?)
        .whereType<int>()
        .toSet();

    var illustrationIndex = -1;
    for (var index = 0; index < _illustrationCycleLength; index++) {
      if (!usedIndices.contains(index)) {
        illustrationIndex = index;
        break;
      }
    }
    if (illustrationIndex == -1) {
      illustrationIndex = existing.length % _illustrationCycleLength;
    }

    await txn.update(
      'categories',
      {'illustration_index': illustrationIndex},
      where: 'id = ?',
      whereArgs: [id],
    );

    return id;
  }

  // Rename an existing category.
  Future<void> renameCategory(int categoryId, String newName) async {
    final normalizedName =
        newName.trim().replaceAll(RegExp(r'\s+'), ' ');

    if (normalizedName.isEmpty) {
      throw ArgumentError('Category name cannot be empty.');
    }

    if (normalizedName.toLowerCase() == 'uncategorized') {
      throw ArgumentError('Uncategorized is a reserved category.');
    }

    final db = await _databaseHelper.database;

    await db.transaction((txn) async {
      final result = await txn.query(
        'categories',
        where: 'id = ?',
        whereArgs: [categoryId],
        limit: 1,
      );

      if (result.isEmpty) {
        throw StateError('Category not found.');
      }

      final category = Category.fromMap(result.first);

      if (!category.canModify) {
        throw StateError('This category cannot be renamed.');
      }

      await txn.update(
        'categories',
        {
          'name': normalizedName,
          'source': 'manual',
        },
        where: 'id = ?',
        whereArgs: [categoryId],
      );

      // Preserve the renamed category during future rescans.
      await txn.update(
        'songs',
        {'category_is_manual': 1},
        where: 'category_id = ?',
        whereArgs: [categoryId],
      );
    });
  }

  // Delete a category and move its songs to Uncategorized.
  Future<void> deleteCategory(int categoryId) async {
    final db = await _databaseHelper.database;

    await db.transaction((txn) async {
      final result = await txn.query(
        'categories',
        where: 'id = ?',
        whereArgs: [categoryId],
        limit: 1,
      );

      if (result.isEmpty) {
        throw StateError('Category not found.');
      }

      final category = Category.fromMap(result.first);

      if (!category.canModify) {
        throw StateError('Uncategorized cannot be deleted.');
      }

      final uncategorizedResult = await txn.query(
        'categories',
        columns: ['id'],
        where: 'is_default = ?',
        whereArgs: [1],
        limit: 1,
      );

      if (uncategorizedResult.isEmpty) {
        throw StateError('Uncategorized category not found.');
      }

      final uncategorizedId =
          uncategorizedResult.first['id'] as int;

      // Preserve Uncategorized assignment during future rescans.
      await txn.update(
        'songs',
        {
          'category_id': uncategorizedId,
          'category_is_manual': 1,
        },
        where: 'category_id = ?',
        whereArgs: [categoryId],
      );

      await txn.delete(
        'categories',
        where: 'id = ?',
        whereArgs: [categoryId],
      );
    });
  }
}
