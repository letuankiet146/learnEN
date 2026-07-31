import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/collection_kids_type.dart';
import '../models/word_game_logic.dart';
import '../providers/app_provider.dart';
import 'word_game_screen.dart';

class WordGameCollectionsScreen extends StatefulWidget {
  const WordGameCollectionsScreen({super.key});

  @override
  State<WordGameCollectionsScreen> createState() =>
      _WordGameCollectionsScreenState();
}

class _WordGameCollectionsScreenState extends State<WordGameCollectionsScreen> {
  final _selectedIds = <String>{};
  final _wordsPerRoundController = TextEditingController();
  bool _wordsPerRoundDirty = false;

  @override
  void dispose() {
    _wordsPerRoundController.dispose();
    super.dispose();
  }

  void _toggleCollection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  List<String> _collectWords(AppProvider provider) {
    final words = provider.sentences
        .where(
          (item) =>
              item.collectionId != null &&
              _selectedIds.contains(item.collectionId),
        )
        .map((item) => item.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    words.shuffle(Random());
    return words;
  }

  void _startGame(AppProvider provider) {
    _saveWordsPerRound(provider);
    final words = _collectWords(provider);
    final wordsPerRound = provider.settings.wordGameWordsPerRound;
    if (words.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cần ít nhất 2 từ vựng để chơi game.',
            style: GoogleFonts.fredoka(),
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WordGameScreen(
          allWords: words,
          wordsPerRound: wordsPerRound,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  int _parseWordsPerRound() {
    final parsed = int.tryParse(_wordsPerRoundController.text.trim());
    if (parsed == null || parsed < 1) {
      return WordGameLogic.defaultWordsPerRound;
    }
    return parsed.clamp(1, 99);
  }

  void _syncWordsPerRoundField(AppProvider provider) {
    if (_wordsPerRoundDirty) return;
    final value = provider.settings.wordGameWordsPerRound;
    final text = '$value';
    if (_wordsPerRoundController.text != text) {
      _wordsPerRoundController.text = text;
    }
  }

  void _saveWordsPerRound(AppProvider provider) {
    final count = _parseWordsPerRound();
    _wordsPerRoundController.text = '$count';
    _wordsPerRoundDirty = false;
    provider.updateSettings(
      provider.settings.copyWith(wordGameWordsPerRound: count),
    );
  }

  Widget _buildWordsPerRoundPicker(AppProvider provider) {
    _syncWordsPerRoundField(provider);

    return Card(
      color: Colors.white.withValues(alpha: 0.92),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Số từ để đầy thanh năng lượng ⚡',
              style: GoogleFonts.fredoka(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF7C2D12),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Học từng từ cho đủ sao ⭐, mỗi từ nạp 1 phần thanh. '
              'Thanh đầy mới qua level tiếp theo.',
              style: GoogleFonts.fredoka(
                fontSize: 15,
                color: const Color(0xFF64748B),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 88,
                  child: TextField(
                    controller: _wordsPerRoundController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fredoka(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFFEA580C),
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (_) => _wordsPerRoundDirty = true,
                    onSubmitted: (_) => _saveWordsPerRound(provider),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'từ / level',
                  style: GoogleFonts.fredoka(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final count in WordGameLogic.wordsPerRoundOptions)
                  ActionChip(
                    label: Text(
                      '$count',
                      style: GoogleFonts.fredoka(fontWeight: FontWeight.w600),
                    ),
                    backgroundColor: const Color(0xFFF1F5F9),
                    onPressed: () {
                      _wordsPerRoundController.text = '$count';
                      _wordsPerRoundDirty = false;
                      provider.updateSettings(
                        provider.settings.copyWith(
                          wordGameWordsPerRound: count,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final collections = provider.collections
            .where((item) => item.kidsType == CollectionKidsType.vocabulary)
            .toList();

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Chọn chủ đề chơi',
              style: GoogleFonts.fredoka(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF7C2D12),
              ),
            ),
            iconTheme: const IconThemeData(color: Color(0xFF7C2D12)),
          ),
          body: Container(
            color: const Color(0xFF87CEEB),
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/shin/cacban.png'),
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                ),
              ),
              child: Container(
                color: Colors.white.withValues(alpha: 0.15),
              child: SafeArea(
                child: collections.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'Chưa có collection từ vựng.\nPhụ huynh hãy tạo trước nhé!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.fredoka(
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF7C2D12),
                              height: 1.4,
                            ),
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                            child: Text(
                              'Chọn một hoặc nhiều chủ đề\nrồi bấm Bắt đầu chơi!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.fredoka(
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF9A3412),
                                height: 1.3,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                            child: _buildWordsPerRoundPicker(provider),
                          ),
                          Expanded(
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 0, 20, 120),
                              itemCount: collections.length,
                              itemBuilder: (context, index) {
                                final collection = collections[index];
                                final count = provider.sentences
                                    .where(
                                      (item) =>
                                          item.collectionId == collection.id,
                                    )
                                    .length;
                                final selected =
                                    _selectedIds.contains(collection.id);
                                final enabled = count > 0;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: Material(
                                    color: selected
                                        ? const Color(0xFF86EFAC)
                                        : Colors.white.withValues(alpha: 0.92),
                                    borderRadius: BorderRadius.circular(24),
                                    elevation: selected ? 6 : 2,
                                    shadowColor: const Color(0xFFEA580C)
                                        .withValues(alpha: 0.35),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(24),
                                      onTap: enabled
                                          ? () =>
                                              _toggleCollection(collection.id)
                                          : null,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 22,
                                        ),
                                        child: Row(
                                          children: [
                                            AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 200,
                                              ),
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: selected
                                                    ? const Color(0xFF16A34A)
                                                    : Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: selected
                                                      ? const Color(0xFF16A34A)
                                                      : const Color(0xFFCBD5E1),
                                                  width: 2.5,
                                                ),
                                              ),
                                              child: selected
                                                  ? const Icon(
                                                      Icons.check_rounded,
                                                      color: Colors.white,
                                                      size: 24,
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    collection.name,
                                                    style: GoogleFonts.fredoka(
                                                      fontSize: 28,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: enabled
                                                          ? const Color(
                                                              0xFF1E293B,
                                                            )
                                                          : const Color(
                                                              0xFF94A3B8,
                                                            ),
                                                    ),
                                                  ),
                                                  Text(
                                                    enabled
                                                        ? '$count từ'
                                                        : 'Chưa có từ nào',
                                                    style: GoogleFonts.fredoka(
                                                      fontSize: 18,
                                                      color: enabled
                                                          ? const Color(
                                                              0xFF64748B,
                                                            )
                                                          : const Color(
                                                              0xFF94A3B8,
                                                            ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (selected)
                                              const Text(
                                                '🌟',
                                                style: TextStyle(fontSize: 28),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                ),
              ),
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: collections.isEmpty
              ? null
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFEA580C),
                        disabledBackgroundColor: const Color(0xFFCBD5E1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: _selectedIds.isEmpty
                          ? null
                          : () => _startGame(provider),
                      child: Text(
                        'Bắt đầu chơi! 🎮',
                        style: GoogleFonts.fredoka(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
