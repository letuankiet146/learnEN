import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_helper.dart';
import '../models/app_settings.dart';
import 'tts_service.dart';

const reminderTaskName = 'learnEnReminderTask';
const notificationChannelId = 'learn_en_reminders';
const notificationChannelName = 'English Reminders';
const speakActionId = 'speak_action';
const _androidNotificationChannel =
    MethodChannel('com.learnen.learn_en/notifications');

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    if (Platform.isIOS) {
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      await _plugin.initialize(
        const InitializationSettings(iOS: iosSettings),
        onDidReceiveNotificationResponse: _onNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );
    } else if (Platform.isAndroid) {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      await _plugin.initialize(
        const InitializationSettings(android: androidSettings),
      );
    }

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        notificationChannelId,
        notificationChannelName,
        description: 'Nhắc nhớ câu tiếng Anh trên lock screen',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
    );

    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final granted = await androidPlugin?.requestNotificationsPermission();
    return granted ?? true;
  }

  Future<void> showSentenceReminder({
    required String sentenceId,
    required String text,
  }) async {
    await initialize();

    if (Platform.isAndroid) {
      await _androidNotificationChannel.invokeMethod<void>(
        'showSentenceReminder',
        {
          'id': sentenceId.hashCode,
          'text': text,
        },
      );
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      notificationChannelId,
      notificationChannelName,
      channelDescription: 'Nhắc nhớ câu tiếng Anh trên lock screen',
      importance: Importance.max,
      priority: Priority.high,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.reminder,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        text,
        contentTitle: 'LearnEN',
        summaryText: 'Tap 🔊 to listen',
      ),
      actions: const [
        AndroidNotificationAction(
          speakActionId,
          '🔊 Speak',
          showsUserInterface: true,
          cancelNotification: false,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.show(
      sentenceId.hashCode,
      'LearnEN',
      text,
      NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: jsonEncode({'id': sentenceId, 'text': text}),
    );
  }

  Future<void> handleNotificationPayload(String? payload) async {
    if (payload == null || payload.isEmpty) return;

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final text = data['text'] as String?;
      if (text != null && text.isNotEmpty) {
        await TtsService.instance.speak(text);
      }
    } catch (_) {
      // Ignore malformed payloads.
    }
  }

  Future<void> _handleNotificationResponse(
    NotificationResponse response,
  ) async {
    if (response.actionId == speakActionId ||
        response.notificationResponseType ==
            NotificationResponseType.selectedNotification) {
      await handleNotificationPayload(response.payload);
    }
  }

  void _onNotificationResponse(NotificationResponse response) {
    _handleNotificationResponse(response);
  }

  static Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedIds = prefs.getStringList('selected_collection_ids') ?? [];

    return AppSettings(
      remindersEnabled: prefs.getBool('reminders_enabled') ?? true,
      reminderIntervalMinutes: prefs.getInt('reminder_interval_minutes') ?? 30,
      useAllCollections: prefs.getBool('use_all_collections') ?? true,
      selectedCollectionIds: selectedIds,
      ttsVoiceGender: prefs.getString('tts_voice_gender'),
    );
  }

  static Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminders_enabled', settings.remindersEnabled);
    await prefs.setInt(
      'reminder_interval_minutes',
      settings.reminderIntervalMinutes,
    );
    await prefs.setBool('use_all_collections', settings.useAllCollections);
    await prefs.setStringList(
      'selected_collection_ids',
      settings.selectedCollectionIds,
    );
    if (settings.ttsVoiceGender == null) {
      await prefs.remove('tts_voice_gender');
    } else {
      await prefs.setString('tts_voice_gender', settings.ttsVoiceGender!);
    }
    await prefs.remove('tts_voice_name');
    await prefs.remove('tts_voice_locale');
  }
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  if (response.actionId == speakActionId ||
      response.notificationResponseType ==
          NotificationResponseType.selectedNotification) {
    NotificationService.instance.handleNotificationPayload(response.payload);
  }
}

Future<void> showRandomReminderFromStorage() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();

  final settings = await NotificationService.loadSettings();
  if (!settings.remindersEnabled) return;

  final sentences = await DatabaseHelper.instance.getActiveSentencesForReminder(
    useAllCollections: settings.useAllCollections,
    collectionIds: settings.selectedCollectionIds,
  );

  if (sentences.isEmpty) return;

  final random = Random();
  final sentence = sentences[random.nextInt(sentences.length)];

  await NotificationService.instance.showSentenceReminder(
    sentenceId: sentence.id,
    text: sentence.text,
  );
}
