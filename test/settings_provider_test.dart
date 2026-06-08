import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integrated_expense/data/models/app_user.dart';
import 'package:integrated_expense/data/models/budget.dart';
import 'package:integrated_expense/data/models/notification_setting.dart';
import 'package:integrated_expense/data/repositories/budget_repository.dart';
import 'package:integrated_expense/data/repositories/notification_repository.dart';
import 'package:integrated_expense/providers/settings_provider.dart';

class _MemorySettingsStore implements SettingsStore {
  String? value;

  @override
  Future<String?> read(String key) async => value;

  @override
  Future<void> write(String key, String value) async {
    this.value = value;
  }
}

class _HangingBudgetRepository extends BudgetRepository {
  @override
  Future<Budget?> fetchByMonth(String userId, String month) =>
      Completer<Budget?>().future;
}

class _HangingNotificationRepository extends NotificationRepository {
  @override
  Future<NotificationSetting?> fetchSetting(String userId) =>
      Completer<NotificationSetting?>().future;
}

void main() {
  test(
    'load keeps user settings when optional remote settings time out',
    () async {
      final now = DateTime(2026, 5, 31);
      final settings = SettingsProvider(
        budgetRepository: _HangingBudgetRepository(),
        notificationRepository: _HangingNotificationRepository(),
        storage: _MemorySettingsStore(),
        remoteLoadTimeout: const Duration(milliseconds: 10),
      );
      final user = AppUser(
        id: 'user-1',
        username: 'tester',
        name: 'Tester',
        monthlyIncome: 123000,
        currency: 'USD',
        language: 'English',
        themeLabel: '다크',
        startScreen: '마이',
        compactView: true,
        showWeeklySummary: false,
        lockOnLaunch: false,
        biometricEnabled: false,
        budgetWarningPrimary: 70,
        budgetWarningSecondary: 90,
        budgetStartDay: '매월 5일',
        isProfileCompleted: true,
        createdAt: now,
        updatedAt: now,
      );

      await expectLater(
        settings.load(user: user).timeout(const Duration(milliseconds: 100)),
        completes,
      );

      expect(settings.isLoaded, isTrue);
      expect(settings.monthlyBudget, 123000);
      expect(settings.currency, 'USD');
      expect(settings.language, 'English');
      expect(settings.themeToken, 'dark');
      expect(settings.startScreen, '마이');
      expect(settings.compactView, isTrue);
      expect(settings.showWeeklySummary, isFalse);
      expect(settings.budgetWarningPrimary, 70);
      expect(settings.budgetWarningSecondary, 90);
      expect(settings.budgetStartDay, '매월 5일');
    },
  );

  test(
    'validateRecoveryCodeForUnlock accepts sha256-prefixed recovery hash',
    () async {
      final now = DateTime(2026, 5, 31);
      const code = 'Recover2026';
      final hash = sha256.convert(utf8.encode(code)).toString();
      final settings = SettingsProvider(storage: _MemorySettingsStore());

      await settings.load(
        user: AppUser(
          id: 'user-1',
          username: 'tester',
          name: 'Tester',
          monthlyIncome: 0,
          currency: 'KRW',
          isProfileCompleted: true,
          createdAt: now,
          updatedAt: now,
          appLockRecoveryCode: 'sha256:$hash',
        ),
      );

      expect(await settings.validateRecoveryCodeForUnlock(code), isTrue);
      expect(await settings.validateRecoveryCodeForUnlock('wrong'), isFalse);
    },
  );
}
