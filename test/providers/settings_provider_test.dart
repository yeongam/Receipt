import 'package:flutter_test/flutter_test.dart';

import 'package:integrated_expense/data/models/app_user.dart';
import 'package:integrated_expense/data/models/budget.dart';
import 'package:integrated_expense/data/models/notification_setting.dart';
import 'package:integrated_expense/data/repositories/auth_repository.dart';
import 'package:integrated_expense/data/repositories/budget_repository.dart';
import 'package:integrated_expense/data/repositories/notification_repository.dart';
import 'package:integrated_expense/providers/settings_provider.dart';

void main() {
  test('설정 변경값은 새 provider 인스턴스에서도 복원된다', () async {
    final storage = _MemorySettingsStore();

    final first = SettingsProvider(storage: storage);
    await first.ready;
    first.updateMonthlyBudget(1750000);
    first.updateAlerts(
      budgetAlert: false,
      fixedExpenseAlert: false,
      reminderAlert: true,
    );
    first.updateLocale(language: 'English', currency: 'USD');
    first.updatePreferences(
      compactView: true,
      showWeeklySummary: false,
      themeLabel: '라이트',
      startScreen: '리포트',
    );
    first.updateSecurity(lockOnLaunch: true, biometric: true);
    await first.ready;

    final second = SettingsProvider(storage: storage);
    await second.ready;

    expect(second.monthlyBudget, 1750000);
    expect(second.budgetAlert, isFalse);
    expect(second.fixedExpenseAlert, isFalse);
    expect(second.reminderAlert, isTrue);
    expect(second.language, 'English');
    expect(second.currency, 'USD');
    expect(second.compactView, isTrue);
    expect(second.showWeeklySummary, isFalse);
    expect(second.startScreen, '리포트');
    expect(second.lockOnLaunch, isTrue);
    expect(second.biometric, isTrue);
  });

  test('저장된 예산과 통화는 loadFromUser 이후에도 유지된다', () async {
    final storage = _MemorySettingsStore();
    final provider = SettingsProvider(storage: storage);
    await provider.ready;

    provider.updateMonthlyBudget(1900000);
    provider.updateLocale(currency: 'JPY');
    await provider.ready;

    provider.loadFromUser(
      AppUser(
        id: 'user-1',
        username: 'testuser',
        name: 'Tester',
        monthlyIncome: 3200000,
        currency: 'KRW',
        isProfileCompleted: true,
        createdAt: DateTime(2026, 4, 29),
        updatedAt: DateTime(2026, 4, 29),
      ),
    );

    expect(provider.monthlyBudget, 1900000);
    expect(provider.currency, 'JPY');
  });

  test('설정 로드 시 사용자, 예산, 알림 저장값을 함께 반영한다', () async {
    final authRepository = _FakeAuthRepository(
      user: _user(
        currency: 'USD',
        language: 'English',
        startScreen: '리포트',
        compactView: true,
        showWeeklySummary: false,
        lockOnLaunch: true,
        biometricEnabled: true,
        budgetWarningPrimary: 70,
        budgetWarningSecondary: 95,
        budgetStartDay: '매월 5일',
      ),
    );
    final budgetRepository = _FakeBudgetRepository(
      budget: _budget(totalLimit: 3500000),
    );
    final notificationRepository = _FakeNotificationRepository(
      setting: _notificationSetting(
        budgetAlertEnabled: false,
        fixedExpenseAlertEnabled: false,
        dailySummaryEnabled: true,
      ),
    );

    final provider = SettingsProvider(
      authRepository: authRepository,
      budgetRepository: budgetRepository,
      notificationRepository: notificationRepository,
      storage: _MemorySettingsStore(),
    );

    await provider.load(user: authRepository.user!);

    expect(provider.monthlyBudget, 3500000);
    expect(provider.currency, 'USD');
    expect(provider.language, 'English');
    expect(provider.startScreen, '리포트');
    expect(provider.compactView, isTrue);
    expect(provider.showWeeklySummary, isFalse);
    expect(provider.lockOnLaunch, isTrue);
    expect(provider.biometric, isTrue);
    expect(provider.budgetWarningPrimary, 70);
    expect(provider.budgetWarningSecondary, 95);
    expect(provider.budgetStartDay, '매월 5일');
    expect(provider.budgetAlert, isFalse);
    expect(provider.fixedExpenseAlert, isFalse);
    expect(provider.reminderAlert, isTrue);
  });

  test('월 예산 변경 시 budgets 저장소에 영속화한다', () async {
    final authRepository = _FakeAuthRepository(user: _user());
    final budgetRepository = _FakeBudgetRepository();
    final notificationRepository = _FakeNotificationRepository(
      setting: _notificationSetting(),
    );
    final provider = SettingsProvider(
      authRepository: authRepository,
      budgetRepository: budgetRepository,
      notificationRepository: notificationRepository,
      storage: _MemorySettingsStore(),
    );

    await provider.load(user: authRepository.user!);
    await provider.updateMonthlyBudget(4200000);

    expect(provider.monthlyBudget, 4200000);
    expect(budgetRepository.lastUpsertedBudget?.totalLimit, 4200000);
  });

  test('첫 화면 변경 시 사용자 프로필 저장소에 영속화한다', () async {
    final authRepository = _FakeAuthRepository(user: _user());
    final budgetRepository = _FakeBudgetRepository();
    final notificationRepository = _FakeNotificationRepository(
      setting: _notificationSetting(),
    );
    final provider = SettingsProvider(
      authRepository: authRepository,
      budgetRepository: budgetRepository,
      notificationRepository: notificationRepository,
      storage: _MemorySettingsStore(),
    );

    await provider.load(user: authRepository.user!);
    await provider.updatePreferences(startScreen: '알림');

    expect(provider.startScreen, '알림');
    expect(authRepository.lastUpdatedUser?.startScreen, '알림');
  });

  test('다른 사용자 설정을 로드할 때 원격 값이 없으면 이전 사용자 값이 남지 않는다', () async {
    final provider = SettingsProvider(
      authRepository: _FakeAuthRepository(
        user: _user(
          monthlyIncome: 0,
        ),
      ),
      budgetRepository: _FakeBudgetRepository(),
      notificationRepository: _FakeNotificationRepository(setting: null),
      storage: _MemorySettingsStore(),
    );

    await provider.ready;
    await provider.updateMonthlyBudget(4200000);
    await provider.updateAlerts(
      budgetAlert: false,
      fixedExpenseAlert: false,
      reminderAlert: true,
    );

    await provider.load(
      user: _user(
        monthlyIncome: 0,
      ),
    );

    expect(provider.monthlyBudget, 2000000);
    expect(provider.budgetAlert, isTrue);
    expect(provider.fixedExpenseAlert, isTrue);
    expect(provider.reminderAlert, isFalse);
  });
}

class _MemorySettingsStore implements SettingsStore {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }
}

class _FakeAuthRepository extends AuthRepository {
  AppUser? user;
  AppUser? lastUpdatedUser;

  _FakeAuthRepository({required this.user});

  @override
  Future<AppUser> updateProfile(AppUser user) async {
    lastUpdatedUser = user;
    this.user = user;
    return user;
  }
}

class _FakeBudgetRepository extends BudgetRepository {
  Budget? budget;
  Budget? lastUpsertedBudget;

  _FakeBudgetRepository({this.budget});

  @override
  Future<Budget?> fetchByMonth(String userId, String month) async => budget;

  @override
  Future<Budget> upsert(Budget budget) async {
    lastUpsertedBudget = budget;
    this.budget = budget;
    return budget;
  }
}

class _FakeNotificationRepository extends NotificationRepository {
  NotificationSetting? setting;

  _FakeNotificationRepository({required this.setting});

  @override
  Future<NotificationSetting?> fetchSetting(String userId) async => setting;

  @override
  Future<NotificationSetting> updateSetting(NotificationSetting setting) async {
    this.setting = setting;
    return setting;
  }
}

AppUser _user({
  int monthlyIncome = 2800000,
  String currency = 'KRW',
  String language = '한국어',
  String startScreen = '홈',
  bool compactView = false,
  bool showWeeklySummary = true,
  String themeLabel = '라이트',
  bool lockOnLaunch = false,
  bool biometricEnabled = false,
  int budgetWarningPrimary = 80,
  int budgetWarningSecondary = 100,
  String budgetStartDay = '매월 1일',
}) {
  return AppUser(
    id: 'user-1',
    username: 'testuser',
    name: '사용자',
    monthlyIncome: monthlyIncome,
    currency: currency,
    language: language,
    themeLabel: themeLabel,
    startScreen: startScreen,
    compactView: compactView,
    showWeeklySummary: showWeeklySummary,
    lockOnLaunch: lockOnLaunch,
    biometricEnabled: biometricEnabled,
    budgetWarningPrimary: budgetWarningPrimary,
    budgetWarningSecondary: budgetWarningSecondary,
    budgetStartDay: budgetStartDay,
    isProfileCompleted: true,
    createdAt: DateTime(2026, 4, 29),
    updatedAt: DateTime(2026, 4, 29),
  );
}

Budget _budget({required int totalLimit}) {
  return Budget(
    id: 'budget-1',
    userId: 'user-1',
    month: '2026-04',
    totalLimit: totalLimit,
    createdAt: DateTime(2026, 4, 29),
    updatedAt: DateTime(2026, 4, 29),
  );
}

NotificationSetting _notificationSetting({
  bool budgetAlertEnabled = true,
  bool fixedExpenseAlertEnabled = true,
  bool dailySummaryEnabled = false,
}) {
  return NotificationSetting(
    id: 'notification-setting-1',
    userId: 'user-1',
    masterEnabled: true,
    budgetAlertEnabled: budgetAlertEnabled,
    fixedExpenseAlertEnabled: fixedExpenseAlertEnabled,
    dailySummaryEnabled: dailySummaryEnabled,
    dailySummaryTime: '20:00',
    createdAt: DateTime(2026, 4, 29),
    updatedAt: DateTime(2026, 4, 29),
  );
}
