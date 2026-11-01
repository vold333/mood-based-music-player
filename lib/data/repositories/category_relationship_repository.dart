import '../../database/database_helper.dart';
import '../models/category_relationship.dart';

class CategoryRelationshipRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Create a relationship between two categories.
  Future<int> addRelationship({
    required int fromCategoryId,
    required int toCategoryId,
    int priority = 1,
  }) async {
    if (fromCategoryId == toCategoryId) {
      throw ArgumentError('A category cannot relate to itself.');
    }

    if (priority < 1) {
      throw ArgumentError('Priority must be at least 1.');
    }

    final db = await _databaseHelper.database;

    return db.insert('category_relationships', {
      'from_category_id': fromCategoryId,
      'to_category_id': toCategoryId,
      'priority': priority,
    });
  }

  // Get all outgoing relationships for a category.
  Future<List<CategoryRelationship>> getRelatedCategories(
    int categoryId,
  ) async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery('''
      SELECT
        cr.*,
        c.name AS to_category_name
      FROM category_relationships cr
      INNER JOIN categories c
        ON c.id = cr.to_category_id
      WHERE cr.from_category_id = ?
      ORDER BY cr.priority ASC, cr.id ASC
    ''', [categoryId]);

    return result
        .map((row) => CategoryRelationship.fromMap(row))
        .toList();
  }

  // Change the priority of an existing relationship.
  Future<int> updatePriority({
    required int relationshipId,
    required int priority,
  }) async {
    if (priority < 1) {
      throw ArgumentError('Priority must be at least 1.');
    }

    final db = await _databaseHelper.database;

    return db.update(
      'category_relationships',
      {'priority': priority},
      where: 'id = ?',
      whereArgs: [relationshipId],
    );
  }

  // Remove a relationship.
  Future<int> removeRelationship(int relationshipId) async {
    final db = await _databaseHelper.database;

    return db.delete(
      'category_relationships',
      where: 'id = ?',
      whereArgs: [relationshipId],
    );
  }
}