import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../widgets/empty_state.dart';
import 'collection_detail_screen.dart';

class CollectionsScreen extends StatelessWidget {
  const CollectionsScreen({super.key});

  Future<void> _createCollection(BuildContext context) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo collection mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Tên collection'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Mô tả (tuỳ chọn)'),
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
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await context.read<AppProvider>().createCollection(
            name: nameController.text,
            description: descriptionController.text,
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
                  itemCount: collections.length,
                  itemBuilder: (context, index) {
                    final collection = collections[index];
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
                                return Text('$count câu');
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
