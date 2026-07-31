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
  final _sentenceFocusNode = FocusNode();
  String? _selectedCollectionId;

  @override
  void dispose() {
    _controller.dispose();
    _sentenceFocusNode.dispose();
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

    _controller.clear();
    _sentenceFocusNode.requestFocus();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã lưu câu. Tiếp tục nhập câu mới.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text('Thêm câu mới'),
            leading: IconButton(
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Đóng',
              onPressed: () => Navigator.pop(context),
            ),
          ),
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
                focusNode: _sentenceFocusNode,
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
                value: _selectedCollectionId,
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
