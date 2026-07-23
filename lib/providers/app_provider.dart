import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/app_settings.dart';
import '../models/sentence.dart';
import '../models/word_collection.dart';
import '../services/notification_service.dart';
import '../services/reminder_service.dart';
import '../services/script_parser_service.dart';
import '../services/tts_service.dart';
import '../services/youtube_service.dart';

class AppProvider extends ChangeNotifier {
  AppProvider();

  final _db = DatabaseHelper.instance;
  final _uuid = const Uuid();
  final _scriptParser = ScriptParserService();
  final _youtubeService = YouTubeService();

  bool _initialized = false;
  bool _loading = false;
  String? _error;

  List<Sentence> _sentences = [];
  List<WordCollection> _collections = [];
  AppSettings _settings = const AppSettings();

  bool get initialized => _initialized;
  bool get loading => _loading;
  String? get error => _error;
  List<Sentence> get sentences => _sentences;
  List<WordCollection> get collections => _collections;
  AppSettings get settings => _settings;

  Future<void> initialize() async {
    if (_initialized) return;

    _loading = true;
    notifyListeners();

    await TtsService.instance.initialize();
    await NotificationService.instance.initialize();
    await NotificationService.instance.requestPermissions();
    await ReminderService.instance.initialize();

    _settings = await NotificationService.loadSettings();
    await TtsService.instance.applyVoiceGender(_settings.ttsVoiceGender);
    await _refreshData();
    await ReminderService.instance.syncSchedule(_settings);

    _loading = false;
    _initialized = true;
    notifyListeners();
  }

  Future<void> _refreshData() async {
    _sentences = await _db.getSentences();
    _collections = await _db.getCollections();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> addSentence({
    required String text,
    String? collectionId,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      _error = 'Câu tiếng Anh không được để trống.';
      notifyListeners();
      return;
    }

    final sentence = Sentence(
      id: _uuid.v4(),
      text: trimmed,
      collectionId: collectionId,
      createdAt: DateTime.now(),
    );

    await _db.insertSentence(sentence);
    await _refreshData();
    notifyListeners();
  }

  Future<void> deleteSentence(String id) async {
    await _db.deleteSentence(id);
    await _refreshData();
    notifyListeners();
  }

  Future<void> toggleSentenceActive(Sentence sentence) async {
    final updated = sentence.copyWith(isActive: !sentence.isActive);
    await _db.updateSentence(updated);
    await _refreshData();
    notifyListeners();
  }

  Future<void> updateSentenceText({
    required String id,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw Exception('Câu tiếng Anh không được để trống.');
    }

    final existing = await _db.getSentence(id);
    if (existing == null) {
      throw Exception('Không tìm thấy câu.');
    }

    await _db.updateSentence(existing.copyWith(text: trimmed));
    await _refreshData();
    notifyListeners();
  }

  Future<void> splitSentence({
    required String id,
    required String firstPart,
    required String secondPart,
  }) async {
    final first = firstPart.trim();
    final second = secondPart.trim();
    if (first.isEmpty || second.isEmpty) {
      throw Exception('Hai phần sau khi tách đều phải có nội dung.');
    }

    final existing = await _db.getSentence(id);
    if (existing == null) {
      throw Exception('Không tìm thấy câu.');
    }

    await _db.updateSentence(existing.copyWith(text: first));
    await _db.insertSentence(
      Sentence(
        id: _uuid.v4(),
        text: second,
        collectionId: existing.collectionId,
        createdAt: DateTime.now(),
        isActive: existing.isActive,
      ),
    );
    await _refreshData();
    notifyListeners();
  }

  Future<void> mergeSentences({
    required String keepId,
    required String removeId,
    required String firstId,
  }) async {
    if (keepId == removeId) {
      throw Exception('Không thể gộp cùng một câu.');
    }

    final keep = await _db.getSentence(keepId);
    final remove = await _db.getSentence(removeId);
    if (keep == null || remove == null) {
      throw Exception('Không tìm thấy câu để gộp.');
    }

    final first = firstId == keep.id ? keep : remove;
    final second = firstId == keep.id ? remove : keep;
    final mergedText = '${first.text} ${second.text}'.replaceAll(
      RegExp(r'\s+'),
      ' ',
    ).trim();

    await _db.updateSentence(keep.copyWith(text: mergedText));
    await _db.deleteSentence(removeId);
    await _refreshData();
    notifyListeners();
  }

  Future<void> assignSentencesToCollection({
    required List<String> sentenceIds,
    required String collectionId,
  }) async {
    if (sentenceIds.isEmpty) {
      throw Exception('Chưa chọn câu nào.');
    }

    final collection = await _db.getCollection(collectionId);
    if (collection == null) {
      throw Exception('Collection không tồn tại.');
    }

    for (final id in sentenceIds) {
      final sentence = await _db.getSentence(id);
      if (sentence != null) {
        await _db.updateSentence(
          sentence.copyWith(collectionId: collectionId),
        );
      }
    }

    await _refreshData();
    notifyListeners();
  }

  Future<void> speakSentence(String text) async {
    await TtsService.instance.speak(text);
  }

  Future<WordCollection> createCollection({
    required String name,
    String? description,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw Exception('Tên collection không được để trống.');
    }

    final collection = WordCollection(
      id: _uuid.v4(),
      name: trimmed,
      description: description?.trim(),
      createdAt: DateTime.now(),
    );

    await _db.insertCollection(collection);
    await _refreshData();
    notifyListeners();
    return collection;
  }

  Future<void> deleteCollection(String id) async {
    await _db.deleteCollection(id);
    _settings = _settings.copyWith(
      selectedCollectionIds: _settings.selectedCollectionIds
          .where((item) => item != id)
          .toList(),
    );
    await NotificationService.saveSettings(_settings);
    await _refreshData();
    await ReminderService.instance.syncSchedule(_settings);
    notifyListeners();
  }

  Future<void> updateSettings(AppSettings settings) async {
    _settings = settings;
    await NotificationService.saveSettings(settings);
    await TtsService.instance.applyVoiceGender(settings.ttsVoiceGender);
    await ReminderService.instance.syncSchedule(settings);
    notifyListeners();
  }

  Future<int> importFromText({
    required String text,
    String? collectionId,
  }) async {
    final parts = _scriptParser.splitIntoSentences(text);
    if (parts.isEmpty) {
      throw Exception('Không tìm thấy câu nào trong script.');
    }

    final now = DateTime.now();
    final sentences = parts
        .map(
          (part) => Sentence(
            id: _uuid.v4(),
            text: part,
            collectionId: collectionId,
            createdAt: now,
          ),
        )
        .toList();

    await _db.insertSentences(sentences);
    await _refreshData();
    notifyListeners();
    return sentences.length;
  }

  Future<int> importFromYouTube({
    required String url,
    String? collectionId,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final transcript = await _youtubeService.fetchTranscript(url);
      final count = await importFromText(
        text: transcript,
        collectionId: collectionId,
      );
      return count;
    } on YouTubeServiceException catch (error) {
      _error = error.message;
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> sendTestNotification() async {
    if (_sentences.isEmpty) {
      _error = 'Hãy thêm ít nhất một câu trước khi test notification.';
      notifyListeners();
      return;
    }

    final active = _sentences.where((item) => item.isActive).toList();
    final pool = active.isEmpty ? _sentences : active;
    final sentence = pool.first;

    await NotificationService.instance.showSentenceReminder(
      sentenceId: sentence.id,
      text: sentence.text,
    );
  }

  Future<int> sentenceCount(String? collectionId) {
    return _db.countSentences(collectionId: collectionId);
  }

  @override
  void dispose() {
    _youtubeService.dispose();
    super.dispose();
  }
}
