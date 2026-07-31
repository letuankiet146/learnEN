import 'dart:math';

class WordGameLogic {
  WordGameLogic({
    required List<String> words,
    List<String>? distractorPool,
    Random? random,
  })  : _words = List<String>.from(words),
        _distractorPool = List<String>.from(distractorPool ?? words),
        _random = random ?? Random();

  static const displayStarCount = 5;
  static const defaultWordsPerRound = 5;
  static const wordsPerRoundOptions = [3, 5, 7, 10];

  static List<String> wordsForRound(
    List<String> allWords,
    int offset,
    int wordsPerRound,
  ) {
    if (offset >= allWords.length || wordsPerRound < 1) return [];
    final end = min(offset + wordsPerRound, allWords.length);
    return allWords.sublist(offset, end);
  }

  final List<String> _words;
  final List<String> _distractorPool;
  final Random _random;

  int wordIndex = 0;
  int starCount = 0;

  bool get isComplete => wordIndex >= _words.length;

  String? get targetWord => isComplete ? null : _words[wordIndex];

  int get totalWords => _words.length;

  int get maxDifficulty => displayStarCount;

  int get difficulty => starCount + 1;

  int get choiceCount => min(starCount + 2, _distractorPool.length);

  bool get isFullStars => starCount >= maxDifficulty;

  List<String> buildChoices() {
    final target = targetWord;
    if (target == null) return const [];

    final distractorCount =
        min(starCount + 1, max(0, _distractorPool.length - 1));
    final distractors = _distractorPool.where((item) => item != target).toList()
      ..shuffle(_random);

    final choices = <String>[target];
    for (final word in distractors) {
      if (choices.length >= distractorCount + 1) break;
      if (!choices.contains(word)) {
        choices.add(word);
      }
    }

    choices.shuffle(_random);
    return choices;
  }

  WordGameAdvanceResult registerCorrect() {
    if (targetWord == null) {
      return const WordGameAdvanceResult(completed: true);
    }

    starCount += 1;

    if (starCount < maxDifficulty) {
      return const WordGameAdvanceResult(leveledUp: true);
    }

    starCount = 0;
    wordIndex += 1;
    if (wordIndex >= _words.length) {
      return const WordGameAdvanceResult(wordMastered: true, completed: true);
    }
    return const WordGameAdvanceResult(wordMastered: true, nextWord: true);
  }

  void registerWrong() {
    starCount = max(0, starCount - 1);
  }
}

class WordGameAdvanceResult {
  const WordGameAdvanceResult({
    this.leveledUp = false,
    this.wordMastered = false,
    this.nextWord = false,
    this.completed = false,
  });

  final bool leveledUp;
  final bool wordMastered;
  final bool nextWord;
  final bool completed;
}
