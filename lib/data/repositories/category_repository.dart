
import '../../database/database_helper.dart';
import '../models/category.dart';

class CategoryRepository {
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

      return txn.insert('categories', {
        'name': normalizedGenre,
        'is_default': 0,
        'source': 'genre',
      });
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

    return db.insert('categories', {
      'name': normalizedName,
      'is_default': 0,
      'source': 'manual',
    });
  }

  // Rename an existing category.
  Future<void> renameCategory(int categoryId, String newName) async {
    final normalizedName = newName.trim().replaceAll(RegExp(r'\s+'), ' ');

    if (normalizedName.isEmpty) {
      throw ArgumentError('Category name cannot be empty.');
    }

    if (normalizedName.toLowerCase() == 'uncategorized') {
      throw ArgumentError('Uncategorized is a reserved category.');
    }

    final db = await _databaseHelper.database;

    final result = await db.query(
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

    await db.update(
      'categories',
      {'name': normalizedName},
      where: 'id = ?',
      whereArgs: [categoryId],
    );
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

      await txn.update(
        'songs',
        {'category_id': uncategorizedId},
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
