import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../data/models/fixed_expense.dart';
import '../data/models/notification_rule.dart';
import '../data/models/notification_setting.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const int _dailyReminderId = 100;
  // Fixed-expense alert IDs start at 1000 and are capped at 1499 (500 slots).
  static const int _fixedExpenseIdStart = 1000;
  static const int _fixedExpenseIdMax = 1500;
  static const String _channelId = 'integrated_expense_alerts';
  static const String _channelName = '통합 지출관리 알림';
  static const String _channelDescription = '리마인더와 고정지출 알림';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Cache the initialisation future so concurrent callers share one result
  // and the plugin is never initialised twice (H-1).
  Future<void>? _initFuture;

  Future<void> initialize() => _initFuture ??= _doInitialize();

  Future<void> _doInitialize() async {
    tz.initializeTimeZones();
    try {
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (_) {
      tz.setLocalLocation(tz.local);
    }

    const androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification');
    const darwinSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _plugin.initialize(settings);
  }

  Future<bool> requestPermissions() async {
    await initialize();

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final iosImpl = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final macImpl = _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();

    final androidGranted =
        await androidImpl?.requestNotificationsPermission() ?? true;
    final iosGranted =
        await iosImpl?.requestPermissions(alert: true, badge: true, sound: true) ??
            true;
    final macGranted =
        await macImpl?.requestPermissions(alert: true, badge: true, sound: true) ??
            true;

    return androidGranted && iosGranted && macGranted;
  }

  // Serialise syncSchedules calls so rapid invocations don't race and leave
  // the notification list in a partially-cancelled state (M-5).
  Future<void> _syncFuture = Future.value();

  /// Reschedules all local notifications based on Supabase settings + fixed expenses.
  /// [rules] provides per-expense is_enabled / remindDaysBefore / remindAt overrides.
  Future<void> syncSchedules({
    required NotificationSetting setting,
    required List<FixedExpense> activeFixedExpenses,
    required bool isEnglish,
    List<NotificationRule> rules = const [],
  }) {
    _syncFuture = _syncFuture.then(
      (_) => _doSyncSchedules(
        setting: setting,
        activeFixedExpenses: activeFixedExpenses,
        isEnglish: isEnglish,
        rules: rules,
      ),
    );
    return _syncFuture;
  }

  Future<void> _doSyncSchedules({
    required NotificationSetting setting,
    required List<FixedExpense> activeFixedExpenses,
    required bool isEnglish,
    List<NotificationRule> rules = const [],
  }) async {
    await initialize();
    await _plugin.cancelAll();

    if (setting.dailySummaryEnabled) {
      await _scheduleDailyReminder(
        time: setting.dailySummaryTime,
        isEnglish: isEnglish,
      );
    }

    if (setting.fixedExpenseAlertEnabled) {
      await _scheduleFixedExpenseAlerts(
        expenses: activeFixedExpenses,
        isEnglish: isEnglish,
        rules: rules,
      );
    }
  }

  Future<void> cancelAll() async {
    await initialize();
    await _plugin.cancelAll();
  }

  Future<void> _scheduleDailyReminder({
    required String time,
    required bool isEnglish,
  }) async {
    final parts = time.split(':');
    final hour = int.tryParse(parts.first) ?? 21;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

    await _plugin.zonedSchedule(
      _dailyReminderId,
      isEnglish ? 'Daily entry reminder' : '오늘 기록을 남겨보세요',
      isEnglish
          ? "Add today's income or expense before the day ends."
          : '하루가 끝나기 전에 오늘의 입출금 내역을 기록해 주세요.',
      _nextInstanceOfTime(hour: hour, minute: minute),
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleFixedExpenseAlerts({
    required List<FixedExpense> expenses,
    required bool isEnglish,
    List<NotificationRule> rules = const [],
  }) async {
    var id = _fixedExpenseIdStart;
    // Only schedule monthly fixed expenses (cycle == 'monthly')
    for (final expense in expenses.where((e) => e.isActive && e.cycle == 'monthly')) {
      // Per-expense rule overrides: is_enabled, remindDaysBefore, remindAt.
      // Falls back to defaults (enabled, 1 day before, 09:00) if no rule exists.
      final rule = rules.where((r) => r.fixedExpenseId == expense.id).firstOrNull;
      if (rule != null && !rule.isEnabled) continue;

      final remindDaysBefore = rule?.remindDaysBefore ?? 1;
      final remindAt = rule?.remindAt ?? '09:00';

      for (var monthOffset = 0; monthOffset < 6; monthOffset++) {
        // Guard against hitting the device alarm limit (L-4).
        if (id >= _fixedExpenseIdMax) {
          debugPrint(
            '[NotificationService] Notification ID limit reached '
            '($_fixedExpenseIdMax), skipping remaining alerts.',
          );
          return;
        }
        try {
          final scheduledDate = _fixedExpenseAlertDate(
            dueDay: expense.billingDay,
            monthOffset: monthOffset,
            remindDaysBefore: remindDaysBefore,
            remindAt: remindAt,
          );
          if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) continue;

          await _plugin.zonedSchedule(
            id++,
            isEnglish ? 'Upcoming fixed expense' : '고정지출 예정 알림',
            isEnglish
                ? '${expense.title} will be deducted in $remindDaysBefore day(s).'
                : '${expense.title} 항목이 $remindDaysBefore일 후 자동 반영될 예정이에요.',
            scheduledDate,
            _notificationDetails(),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
        } catch (e) {
          debugPrint(
            '[NotificationService] Failed to schedule ${expense.title}: $e',
          );
        }
      }
    }
  }

  NotificationDetails _notificationDetails() {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
    );
    const iosDetails = DarwinNotificationDetails();
    return const NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  tz.TZDateTime _nextInstanceOfTime({required int hour, required int minute}) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _fixedExpenseAlertDate({
    required int dueDay,
    required int monthOffset,
    int remindDaysBefore = 1,
    String remindAt = '09:00',
  }) {
    final now = tz.TZDateTime.now(tz.local);
    // Use Dart's DateTime for overflow-safe month arithmetic (month > 12
    // normalises automatically), then construct TZDateTime from the result.
    final rawTarget = DateTime(now.year, now.month + monthOffset, 1);
    final rawLastDay = DateTime(rawTarget.year, rawTarget.month + 1, 0);
    final lastDay = rawLastDay.day;
    final normalizedDay = dueDay.clamp(1, lastDay);
    final parts = remindAt.split(':');
    final hour = int.tryParse(parts.first) ?? 9;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    final dueDate = tz.TZDateTime(
      tz.local,
      rawTarget.year,
      rawTarget.month,
      normalizedDay,
      hour,
      minute,
    );
    return dueDate.subtract(Duration(days: remindDaysBefore));
  }
}
