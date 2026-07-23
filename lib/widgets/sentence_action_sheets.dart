import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sentence.dart';
import '../models/word_collection.dart';
import '../providers/app_provider.dart';

Future<void> showEditSentenceDialog(
  BuildContext context,
  Sentence sentence,
) async {
  final controller = TextEditingController(text: sentence.text);
  final provider = context.read<AppProvider>();

  final saved = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Chỉnh sửa câu'),
      content: TextField(
        controller: controller,
        minLines: 3,
        maxLines: 8,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Nội dung câu',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Lưu'),
        ),
      ],
    ),
  );

  try {
    if (saved == true && context.mounted) {
      await provider.updateSentenceText(
        id: sentence.id,
        text: controller.text,
      );
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  } finally {
    controller.dispose();
  }
}

Future<void> showSplitSentenceSheet(
  BuildContext context,
  Sentence sentence,
) async {
  final provider = context.read<AppProvider>();
  final text = sentence.text;
  var splitIndex = (text.length / 2).round().clamp(1, text.length - 1);

  if (text.length < 2) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Câu quá ngắn, không thể tách.')),
    );
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final firstPart = text.substring(0, splitIndex).trim();
          final secondPart = text.substring(splitIndex).trim();

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Tách câu',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kéo thanh trượt để chọn vị trí tách.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    text,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                Slider(
                  value: splitIndex.toDouble(),
                  min: 1,
                  max: (text.length - 1).toDouble(),
                  divisions: text.length - 2 > 0 ? text.length - 2 : 1,
                  label: splitIndex.toString(),
                  onChanged: (value) {
                    setState(() => splitIndex = value.round());
                  },
                ),
                _SplitPreviewCard(
                  title: 'Câu 1',
                  text: firstPart.isEmpty ? '(trống)' : firstPart,
                ),
                const SizedBox(height: 8),
                _SplitPreviewCard(
                  title: 'Câu 2',
                  text: secondPart.isEmpty ? '(trống)' : secondPart,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: firstPart.isEmpty || secondPart.isEmpty
                      ? null
                      : () async {
                          try {
                            await provider.splitSentence(
                              id: sentence.id,
                              firstPart: firstPart,
                              secondPart: secondPart,
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã tách thành 2 câu.'),
                                ),
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
                  icon: const Icon(Icons.call_split_rounded),
                  label: const Text('Tách thành 2 câu'),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Future<void> showAddToCollectionSheet(
  BuildContext context,
  List<String> sentenceIds,
) async {
  final provider = context.read<AppProvider>();
  final collections = provider.collections;

  if (collections.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chưa có collection. Hãy tạo collection trước.'),
      ),
    );
    return;
  }

  WordCollection? selected = collections.first;

  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Thêm vào collection',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Đã chọn ${sentenceIds.length} câu.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<WordCollection>(
                  initialValue: selected,
                  decoration: const InputDecoration(
                    labelText: 'Collection',
                  ),
                  items: collections
                      .map(
                        (collection) => DropdownMenuItem(
                          value: collection,
                          child: Text(collection.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => selected = value),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: selected == null
                      ? null
                      : () => Navigator.pop(context, true),
                  icon: const Icon(Icons.folder_copy_outlined),
                  label: const Text('Thêm vào collection'),
                ),
              ],
            ),
          );
        },
      );
    },
  );

  if (confirmed != true || selected == null || !context.mounted) return;

  try {
    await provider.assignSentencesToCollection(
      sentenceIds: sentenceIds,
      collectionId: selected!.id,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã thêm ${sentenceIds.length} câu vào ${selected!.name}.',
          ),
        ),
      );
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }
}

class _SplitPreviewCard extends StatelessWidget {
  const _SplitPreviewCard({
    required this.title,
    required this.text,
  });

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(text),
        ],
      ),
    );
  }
}
