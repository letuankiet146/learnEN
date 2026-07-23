import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/sentence.dart';
import 'multi_tap_detector.dart';

class SentenceTile extends StatelessWidget {
  const SentenceTile({
    super.key,
    required this.sentence,
    required this.onSpeak,
    required this.onToggleActive,
    required this.onDelete,
    required this.onEdit,
    required this.onSplit,
    required this.onMergeDrop,
    this.onDragStarted,
    this.onDragUpdate,
    this.onDragEnd,
    this.collectionName,
    this.selectionMode = false,
    this.selected = false,
    this.onSelectionChanged,
  });

  final Sentence sentence;
  final String? collectionName;
  final VoidCallback onSpeak;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onSplit;
  final Future<void> Function(Sentence dragged, Sentence target) onMergeDrop;
  final VoidCallback? onDragStarted;
  final ValueChanged<DragUpdateDetails>? onDragUpdate;
  final VoidCallback? onDragEnd;
  final bool selectionMode;
  final bool selected;
  final ValueChanged<bool>? onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget cardContent({required bool dragHighlighted}) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: dragHighlighted
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.55)
            : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: dragHighlighted
                ? theme.colorScheme.primary
                : Colors.black.withValues(alpha: 0.05),
            width: dragHighlighted ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: selectionMode
              ? () => onSelectionChanged?.call(!selected)
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (selectionMode) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 2, right: 8),
                        child: Checkbox(
                          value: selected,
                          onChanged: (value) {
                            if (value != null) {
                              onSelectionChanged?.call(value);
                            }
                          },
                        ),
                      ),
                    ],
                    Expanded(
                      child: selectionMode
                          ? Text(
                              sentence.text,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            )
                          : MultiTapDetector(
                              onDoubleTap: onEdit,
                              onTripleTap: onSplit,
                              child: Text(
                                sentence.text,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                  color: sentence.isActive
                                      ? theme.colorScheme.onSurface
                                      : theme.colorScheme.onSurface
                                          .withValues(alpha: 0.45),
                                ),
                              ),
                            ),
                    ),
                    if (!selectionMode) ...[
                      IconButton(
                        onPressed: onSpeak,
                        tooltip: 'Đọc câu',
                        icon: const Icon(Icons.volume_up_rounded),
                      ),
                      IconButton(
                        onPressed: onDelete,
                        tooltip: 'Xóa',
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
                if (collectionName != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      collectionName!,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                if (!selectionMode) ...[
                  const SizedBox(height: 8),
                  FilterChip(
                    label: Text(sentence.isActive ? 'Đang nhắc' : 'Tạm dừng'),
                    selected: sentence.isActive,
                    onSelected: (_) => onToggleActive(),
                    showCheckmark: false,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Giữ & kéo để gộp · Double tap sửa · Triple tap tách',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    if (selectionMode) {
      return cardContent(dragHighlighted: false);
    }

    return DragTarget<Sentence>(
      onWillAcceptWithDetails: (details) => details.data.id != sentence.id,
      onAcceptWithDetails: (details) async {
        HapticFeedback.mediumImpact();
        await onMergeDrop(details.data, sentence);
      },
      builder: (context, candidateData, rejectedData) {
        final highlighted = candidateData.isNotEmpty;

        return LongPressDraggable<Sentence>(
          data: sentence,
          hapticFeedbackOnStart: true,
          delay: const Duration(milliseconds: 200),
          onDragStarted: onDragStarted,
          onDragUpdate: onDragUpdate,
          onDragEnd: (_) => onDragEnd?.call(),
          onDraggableCanceled: (_, _) => onDragEnd?.call(),
          feedback: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width - 32,
              ),
              child: Opacity(
                opacity: 0.92,
                child: cardContent(dragHighlighted: true),
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.35,
            child: cardContent(dragHighlighted: false),
          ),
          child: cardContent(dragHighlighted: highlighted),
        );
      },
    );
  }
}
