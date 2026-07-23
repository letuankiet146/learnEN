class ScriptParserService {
  static final _abbreviationPattern = RegExp(
    r'(?:^|\s)(?:Mr|Mrs|Ms|Dr|Prof|Sr|Jr|vs|etc|e\.g|i\.e|U\.S|U\.K|St)\.$',
    caseSensitive: false,
  );

  List<String> splitIntoSentences(String script) {
    final lines = _extractLines(script);
    if (lines.isEmpty) return [];

    final joined = lines.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    final punctuationSplit = _splitByPunctuation(joined);

    if (punctuationSplit.length > 1) {
      return _dedupe(punctuationSplit);
    }

    if (lines.length > 1) {
      final endsWithPunctuation = lines.every(_endsWithSentencePunctuation);
      if (endsWithPunctuation) {
        return _dedupe(lines);
      }

      if (!joined.contains('.') &&
          !joined.contains('!') &&
          !joined.contains('?')) {
        return _dedupe(lines);
      }
    }

    if (punctuationSplit.isEmpty && joined.isNotEmpty) {
      return [joined];
    }

    return _dedupe(punctuationSplit);
  }

  List<String> _extractLines(String script) {
    return script
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  List<String> _splitByPunctuation(String text) {
    if (text.isEmpty) return [];

    final sentences = <String>[];
    final buffer = StringBuffer();

    for (var index = 0; index < text.length; index++) {
      final char = text[index];
      buffer.write(char);

      if (char != '.' && char != '!' && char != '?') {
        continue;
      }

      final current = buffer.toString();
      if (_abbreviationPattern.hasMatch(current)) {
        continue;
      }

      final hasMoreText = index + 1 < text.length;
      if (hasMoreText && !_isSentenceBoundary(text, index + 1)) {
        continue;
      }

      final sentence = current.trim();
      if (sentence.length >= 2) {
        sentences.add(sentence);
      }
      buffer.clear();
    }

    final remainder = buffer.toString().trim();
    if (remainder.length >= 2) {
      sentences.add(remainder);
    }

    return sentences;
  }

  bool _isSentenceBoundary(String text, int index) {
    var cursor = index;
    while (cursor < text.length && text[cursor] == ' ') {
      cursor++;
    }

    if (cursor >= text.length) {
      return true;
    }

    final next = text[cursor];
    final isUppercaseStart =
        next == next.toUpperCase() && next != next.toLowerCase();
    return isUppercaseStart || next == '"' || next == '(' || next == '-';
  }

  bool _endsWithSentencePunctuation(String line) {
    if (line.endsWith('.') || line.endsWith('!') || line.endsWith('?')) {
      return true;
    }

    if (line.length >= 2) {
      final last = line[line.length - 1];
      final before = line[line.length - 2];
      if ((last == '"' || last == "'") &&
          (before == '.' || before == '!' || before == '?')) {
        return true;
      }
    }

    return false;
  }

  List<String> _dedupe(List<String> items) {
    final seen = <String>{};
    final result = <String>[];
    for (final item in items) {
      final key = item.toLowerCase();
      if (seen.add(key)) {
        result.add(item);
      }
    }
    return result;
  }
}
