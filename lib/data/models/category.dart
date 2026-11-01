
class Category {
  final int? id;
  final String name;
  final bool isDefault;
  final String source;

  const Category({
    this.id,
    required this.name,
    this.isDefault = false,
    this.source = 'genre',
  });

  // Convert database Map into Category object.
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      isDefault: map['is_default'] == 1,
      source: map['source'] as String,
    );
  }

  // Convert Category object into database Map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'is_default': isDefault ? 1 : 0,
      'source': source,
    };
  }

  // Uncategorized is protected from rename and deletion.
  bool get canModify => !isDefault;

  Category copyWith({
    int? id,
    String? name,
    bool? isDefault,
    String? source,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
      source: source ?? this.source,
    );
  }
}
