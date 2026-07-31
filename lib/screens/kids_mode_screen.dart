import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/collection_kids_type.dart';
import '../models/sentence.dart';
import '../providers/app_provider.dart';

class KidsModeScreen extends StatelessWidget {
  const KidsModeScreen({
    super.key,
    this.collectionId,
  });

  final String? collectionId;

  static const sentenceFontSize = 48.0;

  Future<void> _confirmExit(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thoát chế độ trẻ em?'),
        content: const Text('Dành cho phụ huynh.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ở lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Thoát'),
          ),
        ],
      ),
    );

    if (shouldExit == true && context.mounted) {
      Navigator.pop(context);
    }
  }

  List<Sentence> _filterSentences(AppProvider provider) {
    if (collectionId == null) {
      return provider.sentences;
    }
    return provider.sentences
        .where((item) => item.collectionId == collectionId)
        .toList();
  }

  CollectionKidsType _kidsTypeForSentence(
    AppProvider provider,
    Sentence sentence,
  ) {
    if (collectionId != null) {
      final collection = provider.collections
          .where((item) => item.id == collectionId)
          .firstOrNull;
      return collection?.kidsType ?? CollectionKidsType.vocabulary;
    }

    if (sentence.collectionId == null) {
      return CollectionKidsType.vocabulary;
    }

    final collection = provider.collections
        .where((item) => item.id == sentence.collectionId)
        .firstOrNull;
    return collection?.kidsType ?? CollectionKidsType.vocabulary;
  }

  String _emptyMessage() {
    if (collectionId != null) {
      return 'Chủ đề này chưa có câu nào.\nPhụ huynh hãy thêm câu trước.';
    }
    return 'Chưa có câu nào.\nPhụ huynh hãy thêm câu trước.';
  }

  List<String> _splitWords(String text) {
    return text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
  }

  TextStyle _wordTextStyle() {
    return GoogleFonts.plusJakartaSans(
      textStyle: const TextStyle(
        fontSize: sentenceFontSize,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: Color(0xFF1E293B),
      ),
    );
  }

  Widget _buildWordChip(String word, {Color? backgroundColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFFFFEDD5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFD6A8),
        ),
      ),
      child: Text(word, style: _wordTextStyle()),
    );
  }

  Widget _buildVocabularySentence(AppProvider provider, String text) {
    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: [
        for (final word in _splitWords(text))
          Material(
            color: const Color(0xFFFFEDD5),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => provider.speakSentence(word),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFFD6A8),
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(word, style: _wordTextStyle()),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDialogueSentence(AppProvider provider, String text) {
    return Material(
      color: const Color(0xFFFFEDD5),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => provider.speakSentence(text),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFFD6A8),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 10,
              children: [
                for (final word in _splitWords(text))
                  _buildWordChip(
                    word,
                    backgroundColor: const Color(0xFFFFF7ED),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSentenceItem(
    AppProvider provider,
    Sentence sentence,
    CollectionKidsType kidsType,
  ) {
    switch (kidsType) {
      case CollectionKidsType.dialogue:
        return _buildDialogueSentence(provider, sentence.text);
      case CollectionKidsType.vocabulary:
        return _buildVocabularySentence(provider, sentence.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final sentences = _filterSentences(provider);

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            await _confirmExit(context);
          },
          child: Scaffold(
            backgroundColor: const Color(0xFFFFF7ED),
            body: SafeArea(
              child: sentences.isEmpty
                  ? GestureDetector(
                      onLongPress: () => _confirmExit(context),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            _emptyMessage(),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    )
                  : GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onLongPress: () => _confirmExit(context),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                        itemCount: sentences.length,
                        itemBuilder: (context, index) {
                          final sentence = sentences[index];
                          final kidsType =
                              _kidsTypeForSentence(provider, sentence);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 28),
                            child: _buildSentenceItem(
                              provider,
                              sentence,
                              kidsType,
                            ),
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
}
