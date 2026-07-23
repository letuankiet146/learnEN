import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final _urlController = TextEditingController();
  String? _selectedCollectionId;
  bool _submitting = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _importFromYouTube() async {
    setState(() => _submitting = true);
    final provider = context.read<AppProvider>();

    try {
      final count = await provider.importFromYouTube(
        url: _urlController.text.trim(),
        collectionId: _selectedCollectionId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã import $count câu từ YouTube.')),
      );
      _urlController.clear();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _importFromFile() async {
    final provider = context.read<AppProvider>();
    final collectionId = _selectedCollectionId;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    String? content;

    if (file.bytes != null) {
      content = String.fromCharCodes(file.bytes!);
    } else if (file.path != null) {
      content = await File(file.path!).readAsString();
    }

    if (content == null || content.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File script trống hoặc không đọc được.')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final count = await provider.importFromText(
        text: content,
        collectionId: collectionId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã import $count câu từ file .txt.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Import script')),
          body: AbsorbPointer(
            absorbing: _submitting || provider.loading,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Import từ YouTube',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Dán link video có phụ đề (subtitle). Nếu video không có phụ đề, hãy upload file .txt.',
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _urlController,
                          decoration: const InputDecoration(
                            labelText: 'YouTube URL',
                            hintText: 'https://www.youtube.com/watch?v=...',
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _importFromYouTube,
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('Tải script từ YouTube'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upload file script (.txt)',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Mỗi dòng hoặc mỗi câu trong file sẽ được tách và lưu riêng.',
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _importFromFile,
                          icon: const Icon(Icons.upload_file_rounded),
                          label: const Text('Chọn file .txt'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: _selectedCollectionId,
                  decoration: const InputDecoration(
                    labelText: 'Lưu vào collection (tuỳ chọn)',
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
                if (_submitting || provider.loading) ...[
                  const SizedBox(height: 24),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
