import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sentence.dart';
import '../providers/app_provider.dart';
import 'sentence_action_sheets.dart';
import 'sentence_tile.dart';

class SentenceListView extends StatefulWidget {
  const SentenceListView({
    super.key,
    required this.sentences,
    required this.selectionMode,
    required this.selectedIds,
    required this.onToggleSelected,
    this.collectionNameFor,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 96),
    this.bottomInset = 72,
  });

  final List<Sentence> sentences;
  final bool selectionMode;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggleSelected;
  final String? Function(Sentence sentence)? collectionNameFor;
  final EdgeInsets padding;
  final double bottomInset;

  @override
  State<SentenceListView> createState() => _SentenceListViewState();
}

class _SentenceListViewState extends State<SentenceListView> {
  static const _edgeZone = 80.0;
  static const _scrollStep = 14.0;

  final ScrollController _scrollController = ScrollController();
  Timer? _autoScrollTimer;
  double _autoScrollDelta = 0;

  @override
  void dispose() {
    _stopAutoScroll();
    _scrollController.dispose();
    super.dispose();
  }

  void _startAutoScroll(double delta) {
    if (_autoScrollDelta == delta && _autoScrollTimer != null) {
      return;
    }

    _autoScrollDelta = delta;
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!_scrollController.hasClients) return;

      final position = _scrollController.position;
      final nextOffset = (_scrollController.offset + delta).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );

      if (nextOffset == _scrollController.offset) {
        _stopAutoScroll();
        return;
      }

      _scrollController.jumpTo(nextOffset);
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    _autoScrollDelta = 0;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final mediaQuery = MediaQuery.of(context);
    final topLimit = mediaQuery.padding.top + kToolbarHeight + _edgeZone;
    final bottomLimit = mediaQuery.size.height -
        mediaQuery.padding.bottom -
        widget.bottomInset -
        _edgeZone;
    final y = details.globalPosition.dy;

    if (y > bottomLimit) {
      _startAutoScroll(_scrollStep);
    } else if (y < topLimit) {
      _startAutoScroll(-_scrollStep);
    } else {
      _stopAutoScroll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();

    return ListView.builder(
      controller: _scrollController,
      padding: widget.padding.copyWith(
        bottom: widget.selectionMode
            ? widget.padding.bottom + 72
            : widget.padding.bottom,
      ),
      itemCount: widget.sentences.length,
      itemBuilder: (context, index) {
        final sentence = widget.sentences[index];
        final selected = widget.selectedIds.contains(sentence.id);

        return SentenceTile(
          sentence: sentence,
          collectionName: widget.collectionNameFor?.call(sentence),
          selectionMode: widget.selectionMode,
          selected: selected,
          onSelectionChanged: (_) => widget.onToggleSelected(sentence.id),
          onSpeak: () => provider.speakSentence(sentence.text),
          onToggleActive: () => provider.toggleSentenceActive(sentence),
          onEdit: () => showEditSentenceDialog(context, sentence),
          onSplit: () => showSplitSentenceSheet(context, sentence),
          onDragUpdate: _handleDragUpdate,
          onDragEnd: _stopAutoScroll,
          onMergeDrop: (dragged, target) async {
            _stopAutoScroll();
            try {
              await provider.mergeSentences(
                keepId: target.id,
                removeId: dragged.id,
                firstId: dragged.id,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã gộp 2 câu.')),
                );
              }
            } catch (error) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error.toString())),
                );
              }
            }
          },
          onDelete: () => _confirmDelete(context, provider, sentence),
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AppProvider provider,
    Sentence sentence,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa câu?'),
        content: const Text('Câu này sẽ không còn xuất hiện trong nhắc nhớ.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.deleteSentence(sentence.id);
    }
  }
}

class SentenceSelectionBar extends StatelessWidget {
  const SentenceSelectionBar({
    super.key,
    required this.selectedCount,
    required this.onAddToCollection,
  });

  final int selectedCount;
  final VoidCallback onAddToCollection;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: FilledButton.icon(
          onPressed: onAddToCollection,
          icon: const Icon(Icons.folder_shared_outlined),
          label: Text(
            selectedCount == 0
                ? 'Thêm vào collection'
                : 'Thêm $selectedCount câu vào collection',
          ),
        ),
      ),
    );
  }
}
