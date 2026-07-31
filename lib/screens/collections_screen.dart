import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/collection_kids_type.dart';
import '../providers/app_provider.dart';
import '../widgets/empty_state.dart';
import 'collection_detail_screen.dart';
import 'kids_collections_screen.dart';
import 'word_game_collections_screen.dart';

class CollectionsScreen extends StatelessWidget {
  const CollectionsScreen({super.key});

  Future<void> _createCollection(BuildContext context) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    var kidsType = CollectionKidsType.vocabulary;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Tạo collection mới'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên collection'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration:
                    const InputDecoration(labelText: 'Mô tả (tuỳ chọn)'),
              ),
              const SizedBox(height: 16),
              Text(
                'Chế độ trẻ em',
                style: Theme.of(context).textTheme.labelLarge,
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
                selected: {kidsType},
                onSelectionChanged: (selected) {
                  setState(() => kidsType = selected.first);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Tạo'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await context.read<AppProvider>().createCollection(
            name: nameController.text,
            description: descriptionController.text,
            kidsType: kidsType,
          );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final collections = provider.collections;

        return Scaffold(
          appBar: AppBar(title: const Text('Collections')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _createCollection(context),
            icon: const Icon(Icons.create_new_folder_outlined),
            label: const Text('Tạo collection'),
          ),
          body: collections.isEmpty
              ? EmptyState(
                  icon: Icons.folder_open_rounded,
                  title: 'Chưa có collection',
                  subtitle:
                      'Nhóm các câu theo chủ đề như Business, Travel, hoặc IELTS.',
                  action: FilledButton.icon(
                    onPressed: () => _createCollection(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Tạo collection đầu tiên'),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: collections.length + 2,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: const Color(0xFFFFF7ED),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: const Icon(
                            Icons.sports_esports_rounded,
                            color: Color(0xFFEA580C),
                            size: 32,
                          ),
                          title: const Text(
                            'Game nhớ từ',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: const Text(
                            'Bé chọn chủ đề và chơi game nhận diện từ vựng.',
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const WordGameCollectionsScreen(),
                                fullscreenDialog: true,
                              ),
                            );
                          },
                        ),
                      );
                    }

                    if (index == 1) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: const Color(0xFFFFF7ED),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: const Icon(
                            Icons.child_care_rounded,
                            color: Color(0xFFEA580C),
                            size: 32,
                          ),
                          title: const Text(
                            'Chế độ trẻ em theo chủ đề',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: const Text(
                            'Bé chọn chủ đề rồi học các câu trong chủ đề đó.',
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const KidsCollectionsScreen(),
                                fullscreenDialog: true,
                              ),
                            );
                          },
                        ),
                      );
                    }

                    final collection = collections[index - 2];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          collection.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (collection.description != null &&
                                collection.description!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(collection.description!),
                              ),
                            const SizedBox(height: 8),
                            FutureBuilder<int>(
                              future: provider.sentenceCount(collection.id),
                              builder: (context, snapshot) {
                                final count = snapshot.data ?? 0;
                                return Text(
                                  '${collection.kidsType.label} · $count câu',
                                );
                              },
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'delete') {
                              await provider.deleteCollection(collection.id);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Xóa collection'),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CollectionDetailScreen(
                                collectionId: collection.id,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
