import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';

class GameFeedbackService {
  GameFeedbackService._();
  static final GameFeedbackService instance = GameFeedbackService._();

  static const _sfxVolume = 0.45;
  static const _celebrationVolume = 0.65;

  final _random = Random();
  final _sfxPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
  final _celebrationPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);

  static const _trueImages = [
    'assets/images/shin/true/dihoc.png',
  ];

  static const _falseImages = [
    'assets/images/shin/false/biandon.webp',
    'assets/images/shin/false/leuleu.webp',
    'assets/images/shin/false/sieunhan.webp',
  ];

  static const _trueSounds = [
    'assets/sounds/true/correct.mp3',
    'assets/sounds/true/yeah.mp3',
  ];

  static const _falseSounds = [
    'assets/sounds/false/uncorrect.mp3',
    'assets/sounds/false/blowing-a-raspberry.mp3',
  ];

  static const _levelCompleteSound = 'assets/sounds/level-complete.mp3';
  static const _gameShowWinSound = 'assets/sounds/game-show-win.mp3';

  String pickTrueImage() => _trueImages[_random.nextInt(_trueImages.length)];

  String pickFalseImage() => _falseImages[_random.nextInt(_falseImages.length)];

  Future<void> playTrueSound() => _playRandom(_sfxPlayer, _trueSounds, _sfxVolume);

  Future<void> playFalseSound() => _playRandom(_sfxPlayer, _falseSounds, _sfxVolume);

  Future<void> playLevelComplete() =>
      _playAsset(_celebrationPlayer, _levelCompleteSound, _celebrationVolume);

  Future<void> playGameShowWin() =>
      _playAsset(_celebrationPlayer, _gameShowWinSound, _celebrationVolume);

  Future<void> _playRandom(
    AudioPlayer player,
    List<String> assets,
    double volume,
  ) async {
    try {
      final asset = assets[_random.nextInt(assets.length)];
      await player.setVolume(volume);
      await player.stop();
      await player.play(AssetSource(asset.replaceFirst('assets/', '')));
    } catch (_) {}
  }

  Future<void> _playAsset(
    AudioPlayer player,
    String asset,
    double volume,
  ) async {
    try {
      await player.setVolume(volume);
      await player.stop();
      final completer = Completer<void>();
      final sub = player.onPlayerComplete.listen((_) {
        if (!completer.isCompleted) completer.complete();
      });
      await player.play(AssetSource(asset.replaceFirst('assets/', '')));
      await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {},
      );
      await sub.cancel();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _sfxPlayer.dispose();
    await _celebrationPlayer.dispose();
  }
}
