class AppSettings {
  const AppSettings({
    this.remindersEnabled = true,
    this.reminderIntervalMinutes = 30,
    this.useAllCollections = true,
    this.selectedCollectionIds = const [],
    this.ttsVoiceGender,
  });

  final bool remindersEnabled;
  final int reminderIntervalMinutes;
  final bool useAllCollections;
  final List<String> selectedCollectionIds;

  /// `female`, `male`, or null for system default.
  final String? ttsVoiceGender;

  static const intervalOptions = [15, 30, 60, 120, 240];
  static const ttsGenderFemale = 'female';
  static const ttsGenderMale = 'male';

  AppSettings copyWith({
    bool? remindersEnabled,
    int? reminderIntervalMinutes,
    bool? useAllCollections,
    List<String>? selectedCollectionIds,
    String? ttsVoiceGender,
    bool clearTtsVoiceGender = false,
  }) {
    return AppSettings(
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      reminderIntervalMinutes:
          reminderIntervalMinutes ?? this.reminderIntervalMinutes,
      useAllCollections: useAllCollections ?? this.useAllCollections,
      selectedCollectionIds:
          selectedCollectionIds ?? this.selectedCollectionIds,
      ttsVoiceGender: clearTtsVoiceGender
          ? null
          : (ttsVoiceGender ?? this.ttsVoiceGender),
    );
  }
}
