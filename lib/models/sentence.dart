class Sentence {
  const Sentence({
    required this.id,
    required this.text,
    this.collectionId,
    required this.createdAt,
    this.isActive = true,
  });

  final String id;
  final String text;
  final String? collectionId;
  final DateTime createdAt;
  final bool isActive;

  Sentence copyWith({
    String? id,
    String? text,
    String? collectionId,
    DateTime? createdAt,
    bool? isActive,
    bool clearCollectionId = false,
  }) {
    return Sentence(
      id: id ?? this.id,
      text: text ?? this.text,
      collectionId: clearCollectionId ? null : (collectionId ?? this.collectionId),
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'collection_id': collectionId,
      'created_at': createdAt.millisecondsSinceEpoch,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory Sentence.fromMap(Map<String, dynamic> map) {
    return Sentence(
      id: map['id'] as String,
      text: map['text'] as String,
      collectionId: map['collection_id'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      isActive: (map['is_active'] as int) == 1,
    );
  }
}
