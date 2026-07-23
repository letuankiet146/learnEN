import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/sentence_action_sheets.dart';
import '../widgets/sentence_list_view.dart';
import 'add_sentence_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  String? _collectionName(AppProvider provider, String? collectionId) {
    if (collectionId == null) return null;
    for (final collection in provider.collections) {
      if (collection.id == collectionId) {
        return collection.name;
      }
    }
    return null;
  }

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
        final sentences = provider.sentences;

        return Scaffold(
          appBar: AppBar(
            title: const Text('LearnEN'),
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
              IconButton(
                tooltip: 'Test notification',
                onPressed: () async {
                  await provider.sendTestNotification();
                  if (context.mounted && provider.error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(provider.error!)),
                    );
                    provider.clearError();
                  }
                },
                icon: const Icon(Icons.notifications_active_outlined),
              ),
            ],
          ),
          floatingActionButton: _selectionMode
              ? null
              : FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AddSentenceScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm câu'),
                ),
          body: sentences.isEmpty
              ? EmptyState(
                  icon: Icons.translate_rounded,
                  title: 'Chưa có câu nào',
                  subtitle:
                      'Thêm câu tiếng Anh để bắt đầu nhận nhắc nhớ trên notification và lock screen.',
                  action: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AddSentenceScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm câu đầu tiên'),
                  ),
                )
              : Stack(
                  children: [
                    SentenceListView(
                      sentences: sentences,
                      selectionMode: _selectionMode,
                      selectedIds: _selectedIds,
                      onToggleSelected: _toggleSelected,
                      collectionNameFor: (sentence) =>
                          _collectionName(provider, sentence.collectionId),
                      bottomInset: _selectionMode ? 144 : 72,
                    ),
                    if (_selectionMode)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: SentenceSelectionBar(
                          selectedCount: _selectedIds.length,
                          onAddToCollection: _addSelectedToCollection,
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}
