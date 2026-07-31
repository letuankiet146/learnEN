enum CollectionKidsType {
  vocabulary,
  dialogue;

  String get label => switch (this) {
        CollectionKidsType.vocabulary => 'Từ vựng',
        CollectionKidsType.dialogue => 'Câu thoại',
      };

  String get storageValue => name;

  static CollectionKidsType fromStorage(String? value) {
    if (value == CollectionKidsType.dialogue.storageValue) {
      return CollectionKidsType.dialogue;
    }
    return CollectionKidsType.vocabulary;
  }
}
