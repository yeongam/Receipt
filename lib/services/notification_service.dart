import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../data/models/fixed_expense.dart';
import '../data/models/notification_setting.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const int _dailyReminderId = 100;
  static const String _channelId = 'integrated_expense_alerts';
  static const String _channelName = '통합 지출관리 알림';
  static const String _channelDescription = '리마인더와 고정지출 알림';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    try {
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (_) {
      tz.setLocalLocation(tz.local);
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _plugin.initialize(settings);
    _initialized = true;
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

  /// Reschedules all local notifications based on Supabase settings + fixed expenses.
  Future<void> syncSchedules({
    required NotificationSetting setting,
    required List<FixedExpense> activeFixedExpenses,
    required bool isEnglish,
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
  }) async {
    var id = 1000;
    // Only schedule monthly fixed expenses (cycle == 'monthly')
    for (final expense in expenses.where((e) => e.isActive && e.cycle == 'monthly')) {
      for (var monthOffset = 0; monthOffset < 6; monthOffset++) {
        try {
          final scheduledDate = _fixedExpenseAlertDate(
            dueDay: expense.billingDay,
            monthOffset: monthOffset,
          );
          if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) continue;

          await _plugin.zonedSchedule(
            id++,
            isEnglish ? 'Upcoming fixed expense' : '고정지출 예정 알림',
            isEnglish
                ? '${expense.title} will be deducted tomorrow.'
                : '${expense.title} 항목이 내일 자동 반영될 예정이에요.',
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
      icon: '@mipmap/ic_launcher',
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
  }) {
    final now = tz.TZDateTime.now(tz.local);
    // Use Dart's DateTime for overflow-safe month arithmetic (month > 12
    // normalises automatically), then construct TZDateTime from the result.
    final rawTarget = DateTime(now.year, now.month + monthOffset, 1);
    final rawLastDay = DateTime(rawTarget.year, rawTarget.month + 1, 0);
    final lastDay = rawLastDay.day;
    final normalizedDay = dueDay.clamp(1, lastDay);
    final dueDate = tz.TZDateTime(
      tz.local,
      rawTarget.year,
      rawTarget.month,
      normalizedDay,
      9,
    );
    return dueDate.subtract(const Duration(days: 1));
  }
}
