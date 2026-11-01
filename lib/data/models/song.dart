
class Song {
  final int? id;
  final String uri;
  final String title;
  final String? artist;
  final String? album;
  final String? genre;
  final int duration;
  final int categoryId;
  final String? categoryName;
  final bool categoryIsManual;

  const Song({
    this.id,
    required this.uri,
    required this.title,
    this.artist,
    this.album,
    this.genre,
    required this.duration,
    required this.categoryId,
    this.categoryName,
    this.categoryIsManual = false,
  });

  // Convert database Map into Song object.
  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'] as int?,
      uri: map['uri'] as String,
      title: map['title'] as String,
      artist: map['artist'] as String?,
      album: map['album'] as String?,
      genre: map['genre'] as String?,
      duration: map['duration'] as int,
      categoryId: map['category_id'] as int,
      categoryName: map['category_name'] as String?,
      categoryIsManual: map['category_is_manual'] == 1,
    );
  }

  // Convert Song object into database Map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uri': uri,
      'title': title,
      'artist': artist,
      'album': album,
      'genre': genre,
      'duration': duration,
      'category_id': categoryId,
      'category_is_manual': categoryIsManual ? 1 : 0,
    };
  }

  // Create a modified copy without changing the original.
  Song copyWith({
    int? id,
    String? uri,
    String? title,
    String? artist,
    String? album,
    String? genre,
    int? duration,
    int? categoryId,
    String? categoryName,
    bool? categoryIsManual,
  }) {
    return Song(
      id: id ?? this.id,
      uri: uri ?? this.uri,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      genre: genre ?? this.genre,
      duration: duration ?? this.duration,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryIsManual: categoryIsManual ?? this.categoryIsManual,
    );
  }
}
