import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/sentence_action_sheets.dart';
import '../widgets/sentence_list_view.dart';

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
          body: sentences.isEmpty
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
        );
      },
    );
  }
}
