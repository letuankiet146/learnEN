class AppSettings {
  const AppSettings({
    this.remindersEnabled = true,
    this.reminderIntervalMinutes = 30,
    this.useAllCollections = true,
    this.selectedCollectionIds = const [],
  });

  final bool remindersEnabled;
  final int reminderIntervalMinutes;
  final bool useAllCollections;
  final List<String> selectedCollectionIds;

  static const intervalOptions = [15, 30, 60, 120, 240];

  AppSettings copyWith({
    bool? remindersEnabled,
    int? reminderIntervalMinutes,
    bool? useAllCollections,
    List<String>? selectedCollectionIds,
  }) {
    return AppSettings(
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      reminderIntervalMinutes:
          reminderIntervalMinutes ?? this.reminderIntervalMinutes,
      useAllCollections: useAllCollections ?? this.useAllCollections,
      selectedCollectionIds:
          selectedCollectionIds ?? this.selectedCollectionIds,
    );
  }
}
