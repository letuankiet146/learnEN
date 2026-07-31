import 'collection_kids_type.dart';

class WordCollection {
  const WordCollection({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    this.isActive = true,
    this.kidsType = CollectionKidsType.vocabulary,
  });

  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final bool isActive;
  final CollectionKidsType kidsType;

  WordCollection copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    bool? isActive,
    CollectionKidsType? kidsType,
  }) {
    return WordCollection(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      kidsType: kidsType ?? this.kidsType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt.millisecondsSinceEpoch,
      'is_active': isActive ? 1 : 0,
      'kids_type': kidsType.storageValue,
    };
  }

  factory WordCollection.fromMap(Map<String, dynamic> map) {
    return WordCollection(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      isActive: (map['is_active'] as int) == 1,
      kidsType: CollectionKidsType.fromStorage(map['kids_type'] as String?),
    );
  }
}
