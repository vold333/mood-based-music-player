class CategoryRelationship {
  final int? id;
  final int fromCategoryId;
  final int toCategoryId;
  final int priority;
  final String? toCategoryName;

  const CategoryRelationship({
    this.id,
    required this.fromCategoryId,
    required this.toCategoryId,
    required this.priority,
    this.toCategoryName,
  });

  factory CategoryRelationship.fromMap(Map<String, dynamic> map) {
    return CategoryRelationship(
      id: map['id'] as int?,
      fromCategoryId: map['from_category_id'] as int,
      toCategoryId: map['to_category_id'] as int,
      priority: map['priority'] as int,
      toCategoryName: map['to_category_name'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'from_category_id': fromCategoryId,
      'to_category_id': toCategoryId,
      'priority': priority,
    };
  }
}