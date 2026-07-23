import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';

class AddSentenceScreen extends StatefulWidget {
  const AddSentenceScreen({super.key});

  @override
  State<AddSentenceScreen> createState() => _AddSentenceScreenState();
}

class _AddSentenceScreenState extends State<AddSentenceScreen> {
  final _controller = TextEditingController();
  String? _selectedCollectionId;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final provider = context.read<AppProvider>();
    await provider.addSentence(
      text: _controller.text,
      collectionId: _selectedCollectionId,
    );

    if (!mounted) return;

    if (provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error!)),
      );
      provider.clearError();
      return;
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Thêm câu mới')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Nhập câu tiếng Anh bạn muốn được nhắc thường xuyên.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                minLines: 3,
                maxLines: 6,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: 'Câu tiếng Anh',
                  hintText: 'Example: Practice makes perfect.',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue: _selectedCollectionId,
                decoration: const InputDecoration(
                  labelText: 'Collection (tuỳ chọn)',
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Không chọn collection'),
                  ),
                  ...provider.collections.map(
                    (collection) => DropdownMenuItem<String?>(
                      value: collection.id,
                      child: Text(collection.name),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedCollectionId = value);
                },
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Lưu câu'),
              ),
            ],
          ),
        );
      },
    );
  }
}
