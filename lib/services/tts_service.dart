import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  static const _androidChannel =
      MethodChannel('com.learnen.learn_en/notifications');

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  String? _voiceName;
  String? _voiceLocale;

  Future<void> initialize() async {
    if (_initialized) return;

    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _initialized = true;
  }

  Future<void> applyVoiceGender(String? gender) async {
    await initialize();

    if (Platform.isAndroid) {
      await _androidChannel.invokeMethod<void>('setTtsGender', <String, dynamic>{
        'gender': gender,
      });

      final resolved = await _androidChannel.invokeMapMethod<String, dynamic>(
        'resolveVoiceForGender',
        <String, dynamic>{'gender': gender},
      );

      if (resolved != null) {
        final name = resolved['name']?.toString();
        final locale = resolved['locale']?.toString();
        if (name != null && name.isNotEmpty) {
          _voiceName = name;
          _voiceLocale = locale ?? 'en-US';
          await _tts.setVoice({
            'name': name,
            'locale': _voiceLocale!,
          });
          return;
        }
      }
    }

    final picked = await _pickVoiceInDart(gender);
    if (picked != null) {
      _voiceName = picked.$1;
      _voiceLocale = picked.$2;
      await _tts.setVoice({
        'name': picked.$1,
        'locale': picked.$2,
      });
    } else {
      _voiceName = null;
      _voiceLocale = null;
      await _tts.setLanguage('en-US');
    }
  }

  Future<(String, String)?> _pickVoiceInDart(String? gender) async {
    if (gender == null || gender.isEmpty) return null;

    final dynamic rawVoices = await _tts.getVoices;
    if (rawVoices is! List) return null;

    final candidates = <(String name, String locale, String? detectedGender)>[];

    for (final item in rawVoices) {
      if (item is! Map) continue;
      final name = item['name']?.toString();
      final locale = item['locale']?.toString();
      if (name == null || locale == null) continue;
      if (!locale.toLowerCase().startsWith('en')) continue;
      candidates.add((name, locale, _detectGender(name)));
    }

    candidates.sort((a, b) {
      final usA = a.$2.toLowerCase().startsWith('en-us') ? 0 : 1;
      final usB = b.$2.toLowerCase().startsWith('en-us') ? 0 : 1;
      if (usA != usB) return usA.compareTo(usB);
      return a.$1.compareTo(b.$1);
    });

    final matched = candidates.where((item) => item.$3 == gender).toList();
    final pool = matched.isNotEmpty ? matched : candidates;
    if (pool.isEmpty) return null;

    final selected = pool.first;
    return (selected.$1, selected.$2);
  }

  String? _detectGender(String voiceName) {
    final lower = voiceName.toLowerCase();
    if (lower.contains('female')) return 'female';
    if (lower.contains('male')) return 'male';
    if (RegExp(r'-(sfg|gba|iob|f)-').hasMatch(lower)) return 'female';
    if (RegExp(r'-(iom|iol|sma|m)-').hasMatch(lower)) return 'male';
    return null;
  }

  Future<void> speak(String text) async {
    await initialize();

    if (_voiceName != null && _voiceName!.isNotEmpty) {
      await _tts.setVoice({
        'name': _voiceName!,
        'locale': _voiceLocale ?? 'en-US',
      });
    } else {
      await _tts.setLanguage('en-US');
    }

    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}
