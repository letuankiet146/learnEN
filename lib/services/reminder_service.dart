import 'package:workmanager/workmanager.dart';

import '../models/app_settings.dart';
import 'notification_service.dart';

class ReminderService {
  ReminderService._();
  static final ReminderService instance = ReminderService._();

  static const taskUniqueName = 'learn_en_periodic_reminder';

  Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher);
  }

  Future<void> syncSchedule(AppSettings settings) async {
    await Workmanager().cancelByUniqueName(taskUniqueName);

    if (!settings.remindersEnabled) return;

    final intervalMinutes = settings.reminderIntervalMinutes < 15
        ? 15
        : settings.reminderIntervalMinutes;

    await Workmanager().registerPeriodicTask(
      taskUniqueName,
      reminderTaskName,
      frequency: Duration(minutes: intervalMinutes),
      initialDelay: Duration(minutes: intervalMinutes),
      constraints: Constraints(
        networkType: NetworkType.not_required,
      ),
    );
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == reminderTaskName) {
      await showRandomReminderFromStorage();
    }
    return true;
  });
}
