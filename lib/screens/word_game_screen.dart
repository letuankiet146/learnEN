import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/word_game_logic.dart';
import '../services/game_feedback_service.dart';
import '../services/tts_service.dart';

enum _ChoiceFeedback { none, correct, wrong }

class WordGameScreen extends StatefulWidget {
  const WordGameScreen({
    super.key,
    required this.allWords,
    required this.wordsPerRound,
    this.wordOffset = 0,
  });

  /// Full shuffled pool (e.g. merged collections).
  final List<String> allWords;

  /// Words needed to fill the energy bar for one round.
  final int wordsPerRound;

  /// Index into [allWords] for the current energy round.
  final int wordOffset;

  @override
  State<WordGameScreen> createState() => _WordGameScreenState();
}

class _WordGameScreenState extends State<WordGameScreen>
    with TickerProviderStateMixin {
  late WordGameLogic _game;
  late List<String> _roundWords;
  late List<String> _choices;
  late List<GlobalKey> _choiceKeys;
  late AnimationController _fireworkController;
  late AnimationController _feedbackImageController;
  late AnimationController _starPulseController;
  late AnimationController _levelCompleteController;
  late AnimationController _wordFlyController;
  late AnimationController _wrongShrinkController;
  late AnimationController _energyPulseController;
  late AnimationController _energyFillController;
  late AnimationController _energyShakeController;
  late AnimationController _energyDrainController;

  final _fireworkSeeds = <_FireworkParticle>[];
  final _energyBarKey = GlobalKey();

  bool _locked = false;
  bool _showLevelComplete = false;
  bool _showWinOverlay = false;
  bool _isEnergyTransition = false;
  double? _displayEnergyProgress;
  String? _feedbackImage;
  _ChoiceFeedback _lastFeedback = _ChoiceFeedback.none;
  int? _tappedIndex;
  int _masteredWords = 0;
  int _pulsingStarIndex = -1;
  int? _starFillOverride;
  int _flyingStarCount = 0;
  List<_StarFlightPath> _starFlightPaths = const [];
  Timer? _winFireworkTimer;
  Rect? _flyFromRect;
  Rect? _flyToRect;
  String? _flyingWord;
  Offset? _fireworkCenter;

  static const _starFlyPortion = 0.58;
  static const _starFadePortion = 0.42;
  static const _starFlyStagger = 0.08;
  static const _starDepartThreshold = 0.04;

  double _starLocalProgress(int index, double progress) {
    final delay = index * _starFlyStagger;
    if (progress <= delay) return 0;
    return ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
  }

  bool _isStarDeparted(int index, double progress) {
    return _starLocalProgress(index, progress) > _starDepartThreshold;
  }

  bool _isStarLitInRow(int index) {
    final filledCount = _starFillOverride ??
        (_showLevelComplete ? _flyingStarCount : _game.starCount);
    if (index >= filledCount) return false;
    if (_showLevelComplete) {
      return !_isStarDeparted(index, _levelCompleteController.value);
    }
    return true;
  }

  double get _energyProgress => _roundWords.isEmpty
      ? 0
      : _masteredWords / _roundWords.length;

  double get _effectiveEnergyProgress =>
      (_displayEnergyProgress ?? _energyProgress).clamp(0.0, 1.0);

  bool get _showGameChrome =>
      _game.targetWord != null ||
      _showLevelComplete ||
      _showWinOverlay ||
      _isEnergyTransition;

  @override
  void initState() {
    super.initState();
    _roundWords = WordGameLogic.wordsForRound(
      widget.allWords,
      widget.wordOffset,
      widget.wordsPerRound,
    );
    _game = WordGameLogic(
      words: _roundWords,
      distractorPool: widget.allWords,
    );
    _choices = _game.buildChoices();
    _choiceKeys = _newChoiceKeys(_choices.length);

    _fireworkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _feedbackImageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _starPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _levelCompleteController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _wordFlyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _wrongShrinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _energyPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _energyFillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _energyShakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _energyDrainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleInitialSpeak());
  }

  Future<void> _scheduleInitialSpeak() async {
    await Future<void>.delayed(const Duration(milliseconds: 750));
    if (!mounted) return;
    await _speakTarget();
  }

  @override
  void dispose() {
    _fireworkController.dispose();
    _feedbackImageController.dispose();
    _starPulseController.dispose();
    _levelCompleteController.dispose();
    _wordFlyController.dispose();
    _wrongShrinkController.dispose();
    _energyPulseController.dispose();
    _energyFillController.dispose();
    _energyShakeController.dispose();
    _energyDrainController.dispose();
    _winFireworkTimer?.cancel();
    TtsService.instance.stop();
    super.dispose();
  }

  List<GlobalKey> _newChoiceKeys(int count) =>
      List.generate(count, (_) => GlobalKey());

  Rect? _globalRectForKey(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Offset? _energyBarCenterGlobal() {
    final box = _energyBarKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(
      Offset(box.size.width / 2, box.size.height / 2),
    );
  }

  static const _feedbackImageHeight = 200.0;

  Rect _flyTargetRect(Rect from, String word) {
    final size = MediaQuery.sizeOf(context);
    const scale = 1.5;
    final fontSize = _fontSizeForWord(word) * scale;
    final width = max(from.width * scale, word.length * fontSize * 0.62 + 48);
    final height = max(from.height * scale, fontSize + 36);
    final imageBottom = size.height / 2 + _feedbackImageHeight / 2;
    final top = imageBottom + 28;
    return Rect.fromLTWH((size.width - width) / 2, top, width, height);
  }

  void _spawnFireworks({Offset? origin}) {
    _fireworkCenter = origin;
    final random = Random();
    _fireworkSeeds
      ..clear()
      ..addAll(
        List.generate(32, (index) {
          final angle = random.nextDouble() * pi * 2;
          final speed = 90 + random.nextDouble() * 140;
          return _FireworkParticle(
            color: [
              const Color(0xFFFF6B6B),
              const Color(0xFFFFD93D),
              const Color(0xFF6BCB77),
              const Color(0xFF4D96FF),
              const Color(0xFFFF85A1),
            ][index % 5],
            dx: cos(angle) * speed,
            dy: sin(angle) * speed,
          );
        }),
      );
    _fireworkController
      ..reset()
      ..forward();
  }

  Future<void> _speakTarget() async {
    final word = _game.targetWord;
    if (word == null) return;
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    await TtsService.instance.speakForGame(word);
  }

  Future<void> _pulseStar(int index) async {
    setState(() => _pulsingStarIndex = index);
    await _starPulseController.forward(from: 0);
    if (!mounted) return;
    _starPulseController.reset();
    setState(() => _pulsingStarIndex = -1);
  }

  Future<void> _animateEnergyFillTo(double target) async {
    final start = _effectiveEnergyProgress;
    _energyFillController.reset();
    void tick() {
      setState(() {
        _displayEnergyProgress =
            start + (target - start) * Curves.easeOutCubic.transform(
                  _energyFillController.value,
                );
      });
    }

    _energyFillController.addListener(tick);
    await _energyFillController.forward();
    _energyFillController.removeListener(tick);
    setState(() => _displayEnergyProgress = target);
  }

  Future<void> _shakeEnergyBar() async {
    HapticFeedback.heavyImpact();
    await _energyShakeController.forward(from: 0);
    if (!mounted) return;
    _energyShakeController.reset();
  }

  Future<void> _runStarAbsorbAnimation({required int starsEarned}) async {
    _prepareStarFlightPaths(starsEarned);
    setState(() => _showLevelComplete = true);
    await _levelCompleteController.forward(from: 0);
    if (!mounted) return;
    setState(() => _showLevelComplete = false);
    _levelCompleteController.reset();
  }

  Future<void> _runWordMasterTransition({
    required int starsEarned,
    required bool isRoundComplete,
  }) async {
    final targetProgress = (_masteredWords + 1) / _roundWords.length;
    final isBarFull = targetProgress >= 1.0;

    setState(() {
      _isEnergyTransition = true;
      _displayEnergyProgress ??= _energyProgress;
    });

    await _runStarAbsorbAnimation(starsEarned: starsEarned);
    if (!mounted) return;

    await _animateEnergyFillTo(targetProgress);
    if (!mounted) return;

    setState(() {
      _masteredWords += 1;
      _starFillOverride = null;
    });

    if (isBarFull) {
      await _shakeEnergyBar();
      if (!mounted) return;
      _spawnFireworks(origin: _energyBarCenterGlobal());
      setState(() {
        _isEnergyTransition = false;
        _displayEnergyProgress = null;
      });
      if (isRoundComplete) {
        await _runWinSequence();
      }
      return;
    }

    setState(() {
      _isEnergyTransition = false;
      _displayEnergyProgress = null;
    });
  }

  Offset? _energyFillTargetGlobal({
    required int index,
    required int total,
  }) {
    final box = _energyBarKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return _energyBarCenterGlobal();

    final progress = _effectiveEnergyProgress;
    final baseX = box.size.width * (progress <= 0 ? 0.06 : progress);
    final spread = (index - (total - 1) / 2) * 8.0;

    return box.localToGlobal(
      Offset(
        (baseX + spread).clamp(12.0, box.size.width - 12.0),
        box.size.height / 2,
      ),
    );
  }

  Offset _starRowGlobalPosition(int index, Size screenSize, EdgeInsets padding) {
    const starCount = WordGameLogic.displayStarCount;
    const starSlotWidth = 50.0;
    final rowRight = screenSize.width - 12;
    final rowLeft = rowRight - starCount * starSlotWidth;
    return Offset(
      rowLeft + index * starSlotWidth + starSlotWidth / 2,
      padding.top + 28,
    );
  }

  void _prepareStarFlightPaths(int count) {
    final random = Random();
    final screenSize = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);

    _flyingStarCount = count;
    _starFlightPaths = List.generate(count, (index) {
      final start = _starRowGlobalPosition(index, screenSize, padding);
      final end = _energyFillTargetGlobal(index: index, total: count) ??
          Offset(screenSize.width / 2, padding.top + 80);
      final mid = Offset.lerp(start, end, 0.45)!;
      final spread = 90 + random.nextDouble() * 130;
      final control1 = Offset(
        mid.dx + (random.nextDouble() - 0.5) * spread,
        start.dy + (random.nextDouble() - 0.2) * spread,
      );
      final control2 = Offset(
        mid.dx + (random.nextDouble() - 0.5) * spread * 0.8,
        end.dy - random.nextDouble() * spread * 0.6,
      );
      return _StarFlightPath(
        start: start,
        control1: control1,
        control2: control2,
        end: end,
      );
    });
  }

  Future<void> _runWinSequence() async {
    setState(() => _showWinOverlay = true);
    _spawnFireworks();
    unawaited(GameFeedbackService.instance.playGameShowWin());

    _winFireworkTimer?.cancel();
    _winFireworkTimer = Timer.periodic(const Duration(milliseconds: 650), (_) {
      if (!mounted || !_showWinOverlay) {
        _winFireworkTimer?.cancel();
        return;
      }
      _spawnFireworks();
    });
  }

  Future<void> _runWordFeedbackAnimation({
    required bool isCorrect,
    required int tappedIndex,
    required int correctIndex,
    required String targetWord,
  }) async {
    if (!isCorrect) {
      await _wrongShrinkController.forward(from: 0);
      if (!mounted) return;
      _wrongShrinkController.reset();
    }

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    final flyIndex = isCorrect ? tappedIndex : correctIndex;
    final fromRect = _globalRectForKey(_choiceKeys[flyIndex]);
    if (fromRect == null) return;

    setState(() {
      _flyingWord = targetWord;
      _flyFromRect = fromRect;
      _flyToRect = _flyTargetRect(fromRect, targetWord);
    });

    await _wordFlyController.forward(from: 0);
    if (!mounted) return;

    await Future<void>.delayed(const Duration(seconds: 2));
  }

  void _resetWordMotion() {
    _wordFlyController.reset();
    _wrongShrinkController.reset();
    _flyFromRect = null;
    _flyToRect = null;
    _flyingWord = null;
  }

  Future<void> _onWordTap(int index, String word) async {
    if (_locked) return;

    final target = _game.targetWord;
    if (target == null) return;

    final isCorrect = word == target;
    final starsRequired = _game.maxDifficulty;
    final correctIndex = _choices.indexOf(target);

    setState(() {
      _locked = true;
      _tappedIndex = index;
      _lastFeedback =
          isCorrect ? _ChoiceFeedback.correct : _ChoiceFeedback.wrong;
    });

    HapticFeedback.mediumImpact();

    try {
      if (isCorrect) {
        final tapRect = _globalRectForKey(_choiceKeys[index]);
        _spawnFireworks(origin: tapRect?.center);
        setState(() {
          _feedbackImage = GameFeedbackService.instance.pickTrueImage();
        });
        await GameFeedbackService.instance.playTrueSound();
      } else {
        setState(() {
          _feedbackImage = GameFeedbackService.instance.pickFalseImage();
        });
        await GameFeedbackService.instance.playFalseSound();
      }

      if (!mounted) return;
      await _feedbackImageController.forward(from: 0);

      await _runWordFeedbackAnimation(
        isCorrect: isCorrect,
        tappedIndex: index,
        correctIndex: correctIndex,
        targetWord: target,
      );
      if (!mounted) return;

      if (_feedbackImageController.status == AnimationStatus.completed) {
        await _feedbackImageController.reverse();
      }

      if (isCorrect) {
        final starsBeforeAnswer = _game.starCount;
        final willMasterWord =
            starsBeforeAnswer == starsRequired - 1;

        if (willMasterWord) {
          setState(() => _starFillOverride = starsRequired);
          await WidgetsBinding.instance.endOfFrame;
        }

        final result = _game.registerCorrect();

        if (result.wordMastered) {
          await _pulseStar(starsRequired - 1);
          await Future<void>.delayed(const Duration(milliseconds: 280));
          await _runWordMasterTransition(
            starsEarned: starsRequired,
            isRoundComplete: result.completed,
          );
          if (result.completed) return;
        } else if (result.leveledUp) {
          await _pulseStar(_game.starCount - 1);
        }
      } else {
        _game.registerWrong();
      }

      setState(() {
        _choices = _game.buildChoices();
        _choiceKeys = _newChoiceKeys(_choices.length);
        _locked = false;
        _lastFeedback = _ChoiceFeedback.none;
        _tappedIndex = null;
        _feedbackImage = null;
      });
      _resetWordMotion();

      if (isCorrect) {
        await Future<void>.delayed(const Duration(milliseconds: 350));
      }
      if (!mounted) return;
      await _speakTarget();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locked = false;
        _lastFeedback = _ChoiceFeedback.none;
        _tappedIndex = null;
        _feedbackImage = null;
      });
      _resetWordMotion();
    }
  }

  double _choiceOpacity(int index) {
    if (!_locked || _lastFeedback == _ChoiceFeedback.none) return 1;

    if (_lastFeedback == _ChoiceFeedback.wrong &&
        index == _tappedIndex &&
        _flyingWord == null) {
      return 1;
    }

    return 0;
  }

  bool _isWrongShrinking(int index) {
    return _locked &&
        _lastFeedback == _ChoiceFeedback.wrong &&
        index == _tappedIndex &&
        _flyingWord == null;
  }

  @override
  Widget build(BuildContext context) {
    final target = _game.targetWord;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final exit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Dừng chơi?',
              style: GoogleFonts.fredoka(fontWeight: FontWeight.w700),
            ),
            content: Text(
              'Bé muốn nghỉ chơi à?',
              style: GoogleFonts.fredoka(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Chơi tiếp'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Nghỉ'),
              ),
            ],
          ),
        );
        if (exit == true && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              color: const Color(0xFF87CEEB),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/shin/cacban.png'),
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Container(color: Colors.white.withValues(alpha: 0.06)),
            if (_showGameChrome)
              SafeArea(
                child: Column(
                  children: [
                    _buildTopBar(),
                    const SizedBox(height: 8),
                    _buildEnergyBar(),
                    const SizedBox(height: 8),
                    _buildListenButton(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                        child: _buildWordChoices(),
                      ),
                    ),
                  ],
                ),
              )
            else if (target == null)
              const Center(child: CircularProgressIndicator()),
            if (_feedbackImage != null) _buildFeedbackOverlay(),
            if (_flyingWord != null && _flyFromRect != null && _flyToRect != null)
              _buildFlyingWordOverlay(),
            if (_showLevelComplete) _buildLevelCompleteOverlay(),
            if (_showWinOverlay) _buildWinOverlay(),
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _fireworkController,
                builder: (context, child) {
                  if (_fireworkController.value <= 0) {
                    return const SizedBox.shrink();
                  }
                  return CustomPaint(
                    size: Size.infinite,
                    painter: _FireworkPainter(
                      progress: _fireworkController.value,
                      particles: _fireworkSeeds,
                      center: _fireworkCenter,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF7C2D12)),
          ),
          const Spacer(),
          _buildStarRow(),
        ],
      ),
    );
  }

  Widget _buildStarRow() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _starPulseController,
        _levelCompleteController,
      ]),
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < WordGameLogic.displayStarCount; i++)
              _buildStar(_isStarLitInRow(i), i),
          ],
        );
      },
    );
  }

  Widget _buildStar(bool filled, int index) {
    final isPulsing = _pulsingStarIndex == index;
    final pulse = isPulsing
        ? 1 + sin(_starPulseController.value * pi * 2) * 0.35
        : 1.0;

    return Transform.scale(
      scale: pulse,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 44,
          color: filled ? const Color(0xFFFFD700) : const Color(0xFFCBD5E1),
          shadows: filled
              ? [
                  Shadow(
                    color: const Color(0xFFFF8C00).withValues(alpha: 0.7),
                    blurRadius: isPulsing ? 16 : 8,
                  ),
                ]
              : null,
        ),
      ),
    );
  }

  Widget _buildEnergyBar() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _energyPulseController,
        _energyShakeController,
      ]),
      builder: (context, child) {
        final pulse = _energyPulseController.value;
        final shakeT = _energyShakeController.value;
        final shake = shakeT > 0
            ? sin(shakeT * pi * 10) * 10 * (1 - shakeT)
            : 0.0;
        final scale = pulse > 0
            ? 1 + sin(pulse * pi) * 0.06
            : shakeT > 0
                ? 1 + sin(shakeT * pi * 6) * 0.08
                : 1.0;
        final glow = pulse > 0
            ? pulse * 0.85
            : shakeT > 0
                ? shakeT * 0.95
                : 0.0;

        return Transform.translate(
          offset: Offset(shake, 0),
          child: Transform.scale(
            scale: scale,
            child: Padding(
              key: _energyBarKey,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Color.lerp(
                      const Color(0xFFFFB347),
                      const Color(0xFFFFD700),
                      glow,
                    )!,
                    width: 3 + glow * 2,
                  ),
                  boxShadow: glow > 0
                      ? [
                          BoxShadow(
                            color:
                                const Color(0xFFFFD700).withValues(alpha: glow),
                            blurRadius: 14 + glow * 10,
                            spreadRadius: glow * 2,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color:
                                const Color(0xFFEA580C).withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                ),
                clipBehavior: Clip.hardEdge,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final fill = _effectiveEnergyProgress;
                    final segmentCount = _roundWords.length;
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            height: 30,
                            width: constraints.maxWidth * fill,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFFFB923C),
                                  Color(0xFFFFD700),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (segmentCount > 1)
                          for (var i = 1; i < segmentCount; i++)
                            Positioned(
                              left: constraints.maxWidth * i / segmentCount - 1,
                              top: 4,
                              bottom: 4,
                              child: Container(
                                width: 2,
                                color: Colors.white.withValues(alpha: 0.55),
                              ),
                            ),
                        Center(
                          child: Text(
                            '⚡',
                            style: TextStyle(
                              fontSize: 18,
                              color: fill > 0.5
                                  ? Colors.white
                                  : const Color(0xFFEA580C),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildListenButton() {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      elevation: 6,
      shadowColor: const Color(0xFFEA580C).withValues(alpha: 0.35),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _locked ? null : _speakTarget,
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFFB347), width: 4),
          ),
          alignment: Alignment.center,
          child: const Text('🎧', style: TextStyle(fontSize: 52)),
        ),
      ),
    );
  }

  Widget _buildWordChoices() {
    return AnimatedBuilder(
      animation: Listenable.merge([_wrongShrinkController, _wordFlyController]),
      builder: (context, child) {
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 14,
          children: [
            for (var i = 0; i < _choices.length; i++)
              _buildChoiceItem(i),
          ],
        );
      },
    );
  }

  Widget _buildChoiceItem(int index) {
    final shrinking = _isWrongShrinking(index);
    final shrinkT = _wrongShrinkController.value;

    Widget button = _WordChoiceButton(
      key: _choiceKeys[index],
      word: _choices[index],
      feedback: _tappedIndex == index ? _lastFeedback : _ChoiceFeedback.none,
      enabled: !_locked,
      onTap: () => _onWordTap(index, _choices[index]),
    );

    if (shrinking) {
      button = Transform.scale(
        scale: 1 - shrinkT * 0.75,
        child: Opacity(
          opacity: (1 - shrinkT).clamp(0.0, 1.0),
          child: button,
        ),
      );
    } else {
      button = AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: _choiceOpacity(index),
        child: button,
      );
    }

    return button;
  }

  Widget _buildFlyingWordOverlay() {
    return AnimatedBuilder(
      animation: _wordFlyController,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_wordFlyController.value);
        final from = _flyFromRect!;
        final to = _flyToRect!;
        final rect = Rect.lerp(from, to, t)!;

        return Positioned(
          left: rect.left,
          top: rect.top,
          width: rect.width,
          height: rect.height,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFF15803D), width: 4),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.45),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _flyingWord!,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: GoogleFonts.fredoka(
                          fontSize: _fontSizeForWord(_flyingWord!) * 1.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  double _fontSizeForWord(String word) {
    if (word.length <= 6) return 38;
    if (word.length <= 10) return 32;
    return 28;
  }

  Widget _buildFeedbackOverlay() {
    return IgnorePointer(
      child: Center(
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: _feedbackImageController,
            curve: Curves.easeOut,
          ),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.5, end: 1).animate(
              CurvedAnimation(
                parent: _feedbackImageController,
                curve: Curves.elasticOut,
              ),
            ),
            child: Image.asset(
              _feedbackImage!,
              height: _feedbackImageHeight,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelCompleteOverlay() {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _levelCompleteController,
        builder: (context, child) {
          final t = _levelCompleteController.value;

          return Stack(
            fit: StackFit.expand,
            children: [
              Container(
                color: Colors.black.withValues(alpha: 0.14 * t),
              ),
              for (var i = 0; i < _flyingStarCount; i++)
                _buildStarToEnergyFlight(index: i, progress: t),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStarToEnergyFlight({
    required int index,
    required double progress,
  }) {
    if (index >= _starFlightPaths.length) {
      return const SizedBox.shrink();
    }

    final localT = _starLocalProgress(index, progress);
    if (localT <= _starDepartThreshold) {
      return const SizedBox.shrink();
    }

    final path = _starFlightPaths[index];
    late Offset pos;
    late double opacity;
    late double scale;
    late double spin;

    if (localT < _starFlyPortion) {
      final flyT = Curves.easeInOutCubic.transform(localT / _starFlyPortion);
      pos = _cubicPoint(path, flyT);
      opacity = 1.0;
      scale = 1.1 - flyT * 0.25;
      spin = flyT * pi * 3 + index;
    } else {
      final fadeT = Curves.easeIn.transform(
        (localT - _starFlyPortion) / _starFadePortion,
      );
      pos = path.end;
      opacity = (1 - fadeT).clamp(0.0, 1.0);
      scale = (0.85 * (1 - fadeT)).clamp(0.0, 1.0);
      spin = pi * 3 + index + fadeT * pi * 2;
    }

    return Positioned(
      left: pos.dx - 22,
      top: pos.dy - 22,
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          child: Transform.rotate(
            angle: spin,
            child: Icon(
              Icons.star_rounded,
              size: 44,
              color: const Color(0xFFFFD700),
              shadows: [
                Shadow(
                  color: const Color(0xFFFF8C00)
                      .withValues(alpha: 0.75 * opacity),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWinOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.45),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(28),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEA580C).withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 8),
              Text(
                'Giỏi lắm!',
                style: GoogleFonts.fredoka(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFEA580C),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    _winFireworkTimer?.cancel();
                    await TtsService.instance.stop();

                    var allWords = widget.allWords;
                    var nextOffset =
                        widget.wordOffset + _roundWords.length;

                    if (nextOffset >= allWords.length) {
                      allWords = List<String>.from(widget.allWords)
                        ..shuffle();
                      nextOffset = 0;
                    }

                    if (!mounted) return;
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => WordGameScreen(
                          allWords: allWords,
                          wordOffset: nextOffset,
                          wordsPerRound: widget.wordsPerRound,
                        ),
                        fullscreenDialog: true,
                      ),
                    );
                  },
                  child: Text(
                    'Chơi tiếp 🔄',
                    style: GoogleFonts.fredoka(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFEA580C), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    _winFireworkTimer?.cancel();
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Thoát',
                    style: GoogleFonts.fredoka(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFEA580C),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WordChoiceButton extends StatefulWidget {
  const _WordChoiceButton({
    super.key,
    required this.word,
    required this.feedback,
    required this.enabled,
    required this.onTap,
  });

  final String word;
  final _ChoiceFeedback feedback;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_WordChoiceButton> createState() => _WordChoiceButtonState();
}

class _WordChoiceButtonState extends State<_WordChoiceButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void didUpdateWidget(covariant _WordChoiceButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.feedback != _ChoiceFeedback.none &&
        oldWidget.feedback == _ChoiceFeedback.none) {
      _controller.forward(from: 0);
    }
    if (widget.feedback == _ChoiceFeedback.none &&
        oldWidget.feedback != _ChoiceFeedback.none) {
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _backgroundColor() {
    return switch (widget.feedback) {
      _ChoiceFeedback.correct => const Color(0xFF22C55E),
      _ChoiceFeedback.wrong => const Color(0xFFEF4444),
      _ChoiceFeedback.none => const Color(0xFFFFF1DC),
    };
  }

  Color _borderColor() {
    return switch (widget.feedback) {
      _ChoiceFeedback.correct => const Color(0xFF15803D),
      _ChoiceFeedback.wrong => const Color(0xFFB91C1C),
      _ChoiceFeedback.none => const Color(0xFFFFB347),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isWrong = widget.feedback == _ChoiceFeedback.wrong;
    final isCorrect = widget.feedback == _ChoiceFeedback.correct;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final scale = isCorrect
            ? 1 + sin(t * pi) * 0.18 * (1 - t)
            : isWrong
                ? 1 - t * 0.12
                : 1.0;
        final squish = isWrong ? 1 - t * 0.25 : 1.0;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..scaleByDouble(scale, scale * squish, 1, 1),
          child: child,
        );
      },
      child: Material(
        color: _backgroundColor(),
        borderRadius: BorderRadius.circular(22),
        elevation: widget.feedback == _ChoiceFeedback.none ? 4 : 0,
        shadowColor: const Color(0xFFEA580C).withValues(alpha: 0.35),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: widget.enabled ? widget.onTap : null,
          child: Container(
            constraints: const BoxConstraints(minWidth: 130, minHeight: 68),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _borderColor(), width: 4),
            ),
            alignment: Alignment.center,
            child: Text(
              widget.word,
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: _fontSizeForWord(widget.word),
                fontWeight: FontWeight.w800,
                color: widget.feedback == _ChoiceFeedback.none
                    ? const Color(0xFF1E293B)
                    : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _fontSizeForWord(String word) {
    if (word.length <= 6) return 38;
    if (word.length <= 10) return 32;
    return 28;
  }
}

class _StarFlightPath {
  const _StarFlightPath({
    required this.start,
    required this.control1,
    required this.control2,
    required this.end,
  });

  final Offset start;
  final Offset control1;
  final Offset control2;
  final Offset end;
}

Offset _cubicPoint(_StarFlightPath path, double t) {
  final u = 1 - t;
  final tt = t * t;
  final uu = u * u;
  final uuu = uu * u;
  final ttt = tt * t;

  return Offset(
    uuu * path.start.dx +
        3 * uu * t * path.control1.dx +
        3 * u * tt * path.control2.dx +
        ttt * path.end.dx,
    uuu * path.start.dy +
        3 * uu * t * path.control1.dy +
        3 * u * tt * path.control2.dy +
        ttt * path.end.dy,
  );
}

class _FireworkParticle {
  const _FireworkParticle({
    required this.color,
    required this.dx,
    required this.dy,
  });

  final Color color;
  final double dx;
  final double dy;
}

class _FireworkPainter extends CustomPainter {
  _FireworkPainter({
    required this.progress,
    required this.particles,
    this.center,
  });

  final double progress;
  final List<_FireworkParticle> particles;
  final Offset? center;

  @override
  void paint(Canvas canvas, Size size) {
    if (particles.isEmpty || progress <= 0) return;

    final burstCenter = center ?? Offset(size.width / 2, size.height * 0.42);
    final paint = Paint()..style = PaintingStyle.fill;

    for (final particle in particles) {
      paint.color =
          particle.color.withValues(alpha: (1 - progress).clamp(0.0, 1.0));
      final offset = burstCenter +
          Offset(
            particle.dx * progress,
            particle.dy * progress + 40 * progress,
          );
      canvas.drawCircle(offset, 6 * (1 - progress * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FireworkPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.center != center;
  }
}
