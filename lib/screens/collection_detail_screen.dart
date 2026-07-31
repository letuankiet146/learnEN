import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/collection_kids_type.dart';
import '../providers/app_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/sentence_action_sheets.dart';
import '../widgets/sentence_list_view.dart';
import 'kids_mode_screen.dart';

class CollectionDetailScreen extends StatefulWidget {
  const CollectionDetailScreen({
    super.key,
    required this.collectionId,
  });

  final String collectionId;

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      if (!_selectionMode) {
        _selectedIds.clear();
      }
    });
  }

  void _toggleSelected(String sentenceId) {
    setState(() {
      if (_selectedIds.contains(sentenceId)) {
        _selectedIds.remove(sentenceId);
      } else {
        _selectedIds.add(sentenceId);
      }
    });
  }

  Future<void> _addSelectedToCollection() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hãy chọn ít nhất một câu.')),
      );
      return;
    }

    await showAddToCollectionSheet(context, _selectedIds.toList());

    if (mounted) {
      setState(() {
        _selectionMode = false;
        _selectedIds.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final collection = provider.collections
            .where((item) => item.id == widget.collectionId)
            .firstOrNull;

        if (collection == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Collection')),
            body: const Center(child: Text('Collection không tồn tại.')),
          );
        }

        final sentences = provider.sentences
            .where((item) => item.collectionId == widget.collectionId)
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(collection.name),
            actions: [
              if (sentences.isNotEmpty)
                IconButton(
                  tooltip: 'Chế độ trẻ em',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => KidsModeScreen(
                          collectionId: collection.id,
                        ),
                        fullscreenDialog: true,
                      ),
                    );
                  },
                  icon: const Icon(Icons.child_care_rounded),
                ),
              if (sentences.isNotEmpty)
                IconButton(
                  tooltip: _selectionMode
                      ? 'Huỷ chọn'
                      : 'Chọn câu để thêm vào collection',
                  onPressed: _toggleSelectionMode,
                  icon: Icon(
                    _selectionMode
                        ? Icons.close_rounded
                        : Icons.playlist_add_check_rounded,
                  ),
                ),
            ],
          ),
          bottomNavigationBar: _selectionMode
              ? SentenceSelectionBar(
                  selectedCount: _selectedIds.length,
                  onAddToCollection: _addSelectedToCollection,
                )
              : null,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chế độ trẻ em',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<CollectionKidsType>(
                          segments: const [
                            ButtonSegment(
                              value: CollectionKidsType.vocabulary,
                              label: Text('Từ vựng'),
                              icon: Icon(Icons.abc_rounded),
                            ),
                            ButtonSegment(
                              value: CollectionKidsType.dialogue,
                              label: Text('Câu thoại'),
                              icon: Icon(Icons.chat_bubble_outline_rounded),
                            ),
                          ],
                          selected: {collection.kidsType},
                          onSelectionChanged: (selected) {
                            provider.updateCollection(
                              collection.copyWith(kidsType: selected.first),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          collection.kidsType ==
                                  CollectionKidsType.vocabulary
                              ? 'Bé chạm từng chữ để nghe.'
                              : 'Bé chạm cả câu để nghe một lượt.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: sentences.isEmpty
                    ? EmptyState(
                        icon: Icons.menu_book_outlined,
                        title: 'Collection trống',
                        subtitle:
                            'Thêm câu hoặc import script và chọn collection này.',
                      )
                    : SentenceListView(
                        sentences: sentences,
                        selectionMode: _selectionMode,
                        selectedIds: _selectedIds,
                        onToggleSelected: _toggleSelected,
                        collectionNameFor: (_) => collection.name,
                        padding: const EdgeInsets.all(16),
                        bottomInset: _selectionMode ? 72 : 16,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
