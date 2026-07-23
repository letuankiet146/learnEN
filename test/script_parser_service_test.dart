import 'package:flutter_test/flutter_test.dart';
import 'package:learn_en/services/script_parser_service.dart';

void main() {
  final parser = ScriptParserService();

  test('joins youtube caption lines into full sentences', () {
    const script = '''
ACID stands for Atomicity, Consistency,
Isolation, and Durability - the four key
properties of database transactions.
Next, we discuss isolation levels.
''';

    final result = parser.splitIntoSentences(script);

    expect(result.length, 2);
    expect(
      result.first,
      'ACID stands for Atomicity, Consistency, Isolation, and Durability - the four key properties of database transactions.',
    );
    expect(result.last, 'Next, we discuss isolation levels.');
  });

  test('keeps one sentence per line for plain txt files', () {
    const script = '''
Hello world
How are you
Nice to meet you
''';

    final result = parser.splitIntoSentences(script);

    expect(result, [
      'Hello world',
      'How are you',
      'Nice to meet you',
    ]);
  });

  test('splits long paragraph by punctuation', () {
    const script =
        'First sentence here. Second sentence here! Is this a question?';

    final result = parser.splitIntoSentences(script);

    expect(result, [
      'First sentence here.',
      'Second sentence here!',
      'Is this a question?',
    ]);
  });
}
