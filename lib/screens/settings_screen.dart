import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_settings.dart';
import '../providers/app_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  String _intervalLabel(int minutes) {
    if (minutes < 60) return '$minutes phút';
    if (minutes == 60) return '1 giờ';
    if (minutes == 120) return '2 giờ';
    if (minutes == 240) return '4 giờ';
    return '$minutes phút';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final settings = provider.settings;

        return Scaffold(
          appBar: AppBar(title: const Text('Cài đặt nhắc nhớ')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: SwitchListTile(
                  title: const Text('Bật nhắc nhớ'),
                  subtitle: const Text(
                    'Hiển thị câu tiếng Anh qua notification và lock screen.',
                  ),
                  value: settings.remindersEnabled,
                  onChanged: (value) {
                    provider.updateSettings(
                      settings.copyWith(remindersEnabled: value),
                    );
                  },
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
                        'Tần suất nhắc',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Android tối thiểu 15 phút/lần do giới hạn hệ thống.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: AppSettings.intervalOptions.map((minutes) {
                          final selected =
                              settings.reminderIntervalMinutes == minutes;
                          return ChoiceChip(
                            label: Text(_intervalLabel(minutes)),
                            selected: selected,
                            onSelected: (_) {
                              provider.updateSettings(
                                settings.copyWith(
                                  reminderIntervalMinutes: minutes,
                                ),
                              );
                            },
                          );
                        }).toList(),
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
                        'Nguồn câu nhắc',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Dùng tất cả câu'),
                        value: settings.useAllCollections,
                        onChanged: (value) {
                          provider.updateSettings(
                            settings.copyWith(useAllCollections: value),
                          );
                        },
                      ),
                      if (!settings.useAllCollections) ...[
                        const Divider(),
                        ...provider.collections.map((collection) {
                          final selected = settings.selectedCollectionIds
                              .contains(collection.id);
                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(collection.name),
                            value: selected,
                            onChanged: (value) {
                              final ids =
                                  List<String>.from(settings.selectedCollectionIds);
                              if (value == true) {
                                ids.add(collection.id);
                              } else {
                                ids.remove(collection.id);
                              }
                              provider.updateSettings(
                                settings.copyWith(selectedCollectionIds: ids),
                              );
                            },
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('Lock screen & TTS'),
                  subtitle: const Text(
                    'Notification hiển thị trên lock screen. Nhấn 🔊 Speak hoặc tap notification để nghe câu.',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => provider.sendTestNotification(),
                icon: const Icon(Icons.notifications_none_rounded),
                label: const Text('Gửi notification thử'),
              ),
            ],
          ),
        );
      },
    );
  }
}
