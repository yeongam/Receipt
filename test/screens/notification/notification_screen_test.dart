import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:integrated_expense/data/models/app_user.dart';
import 'package:integrated_expense/data/models/fixed_expense.dart';
import 'package:integrated_expense/data/models/notification_rule.dart';
import 'package:integrated_expense/data/repositories/auth_repository.dart';
import 'package:integrated_expense/data/repositories/fixed_expense_repository.dart';
import 'package:integrated_expense/data/repositories/notification_repository.dart';
import 'package:integrated_expense/providers/auth_provider.dart';
import 'package:integrated_expense/providers/fixed_expense_provider.dart';
import 'package:integrated_expense/providers/notification_rule_provider.dart';
import 'package:integrated_expense/providers/settings_provider.dart';
import 'package:integrated_expense/screens/notification/notification_screen.dart';

void main() {
  testWidgets('고정지출 추가 버튼으로 항목을 등록할 수 있다', (tester) async {
    final authProvider = AuthProvider(_FakeAuthRepository());
    await authProvider.signIn(username: 'testuser', password: 'pw');
    final fixedExpenseProvider =
        FixedExpenseProvider(_FakeFixedExpenseRepository());
    final ruleProvider =
        NotificationRuleProvider(_FakeNotificationRepository());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<FixedExpenseProvider>.value(
            value: fixedExpenseProvider,
          ),
          ChangeNotifierProvider<NotificationRuleProvider>.value(
            value: ruleProvider,
          ),
          // Required by _FixedExpenseTile which uses context.formatCurrency().
          ChangeNotifierProvider(
            create: (_) => SettingsProvider(storage: _MemorySettingsStore()),
          ),
        ],
        child: const MaterialApp(
          home: NotificationScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add_circle_outline_rounded));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, '예: 월세, 통신비'),
      '월세',
    );
    await tester.enterText(
      find.widgetWithText(TextField, '숫자만 입력'),
      '850000',
    );
    await tester.enterText(
      find.widgetWithText(TextField, '1~31'),
      '25',
    );
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(find.text('월세'), findsOneWidget);
    expect(find.text('매월 25일 · 월정기'), findsOneWidget);
    // SettingsProvider defaults to KRW → formatCurrency(850000) == '₩850,000'
    expect(find.text('₩850,000'), findsWidgets);
  });
}

class _FakeAuthRepository extends AuthRepository {
  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();

  @override
  Future<AppUser> signIn({
    required String username,
    required String password,
  }) async {
    return AppUser(
      id: 'user-1',
      username: username,
      name: 'Tester',
      monthlyIncome: 2500000,
      currency: 'KRW',
      isProfileCompleted: true,
      createdAt: DateTime(2026, 4, 29),
      updatedAt: DateTime(2026, 4, 29),
    );
  }
}

class _FakeNotificationRepository extends NotificationRepository {
  @override
  Future<List<NotificationRule>> fetchRules(String userId) async => [];

  @override
  Future<NotificationRule> insertRule(NotificationRule rule) async => rule;
}

class _FakeFixedExpenseRepository extends FixedExpenseRepository {
  int _nextId = 1;

  @override
  Future<FixedExpense> insert(FixedExpense fe) async {
    return FixedExpense(
      id: 'fixed-${_nextId++}',
      userId: fe.userId,
      categoryId: fe.categoryId,
      title: fe.title,
      amount: fe.amount,
      cycle: fe.cycle,
      billingDay: fe.billingDay,
      nextDueDate: fe.nextDueDate,
      memo: fe.memo,
      isActive: fe.isActive,
      createdAt: fe.createdAt,
      updatedAt: fe.updatedAt,
    );
  }
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
