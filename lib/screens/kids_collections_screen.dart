import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import 'kids_mode_screen.dart';

class KidsCollectionsScreen extends StatelessWidget {
  const KidsCollectionsScreen({super.key});

  Future<void> _confirmExit(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thoát chế độ trẻ em?'),
        content: const Text('Dành cho phụ huynh.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ở lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Thoát'),
          ),
        ],
      ),
    );

    if (shouldExit == true && context.mounted) {
      Navigator.pop(context);
    }
  }

  void _openCollection(
    BuildContext context,
    String collectionId,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => KidsModeScreen(
          collectionId: collectionId,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final collections = provider.collections;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            await _confirmExit(context);
          },
          child: Scaffold(
            backgroundColor: const Color(0xFFFFF7ED),
            body: SafeArea(
              child: collections.isEmpty
                  ? GestureDetector(
                      onLongPress: () => _confirmExit(context),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'Chưa có chủ đề nào.\nPhụ huynh hãy tạo collection trước.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    )
                  : GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onLongPress: () => _confirmExit(context),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                        itemCount: collections.length,
                        itemBuilder: (context, index) {
                          final collection = collections[index];
                          final sentenceCount = provider.sentences
                              .where((item) => item.collectionId == collection.id)
                              .length;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Material(
                              color: const Color(0xFFFFE4C7),
                              borderRadius: BorderRadius.circular(24),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onTap: sentenceCount == 0
                                    ? null
                                    : () => _openCollection(
                                          context,
                                          collection.id,
                                        ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 28,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          collection.name,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 36,
                                            fontWeight: FontWeight.w800,
                                            height: 1.2,
                                            color: sentenceCount == 0
                                                ? const Color(0xFF94A3B8)
                                                : const Color(0xFF1E293B),
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 40,
                                        color: sentenceCount == 0
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFFEA580C),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}
