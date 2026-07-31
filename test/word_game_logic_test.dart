import 'package:flutter_test/flutter_test.dart';
import 'package:learn_en/models/word_game_logic.dart';

void main() {
  group('WordGameLogic buildChoices', () {
    test('uses full collection as distractors when round has one word', () {
      const pool = ['apple', 'banana', 'cat', 'dog', 'egg', 'fox', 'goat'];
      final game = WordGameLogic(
        words: const ['apple'],
        distractorPool: pool,
      );

      final choices = game.buildChoices();

      expect(choices, contains('apple'));
      expect(choices.length, 2);
      expect(choices.where((word) => word != 'apple').length, 1);
    });

    test('adds one more distractor after each correct answer', () {
      const pool = ['apple', 'banana', 'cat', 'dog', 'egg', 'fox', 'goat'];
      final game = WordGameLogic(
        words: const ['apple'],
        distractorPool: pool,
      );

      expect(game.buildChoices().length, 2);

      game.registerCorrect();
      expect(game.buildChoices().length, 3);

      game.registerCorrect();
      expect(game.buildChoices().length, 4);
    });

    test('removes one distractor level after wrong answer', () {
      const pool = ['apple', 'banana', 'cat', 'dog', 'egg', 'fox', 'goat'];
      final game = WordGameLogic(
        words: const ['apple'],
        distractorPool: pool,
      );

      game.registerCorrect();
      game.registerCorrect();
      expect(game.buildChoices().length, 4);

      game.registerWrong();
      expect(game.buildChoices().length, 3);
    });
  });
}
