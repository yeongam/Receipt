import 'package:flutter_test/flutter_test.dart';
import 'package:integrated_expense/data/models/category.dart';
import 'package:integrated_expense/data/models/fixed_expense.dart';
import 'package:integrated_expense/data/models/notification_rule.dart';
import 'package:integrated_expense/data/models/transaction.dart';
import 'package:integrated_expense/data/repositories/category_repository.dart';
import 'package:integrated_expense/data/repositories/fixed_expense_repository.dart';
import 'package:integrated_expense/data/repositories/notification_repository.dart';
import 'package:integrated_expense/data/repositories/transaction_repository.dart';
import 'package:integrated_expense/providers/category_provider.dart';
import 'package:integrated_expense/providers/fixed_expense_provider.dart';
import 'package:integrated_expense/providers/notification_rule_provider.dart';
import 'package:integrated_expense/providers/transaction_provider.dart';

class _RecordingTransactionRepository extends TransactionRepository {
  String? deletedId;
  String? deletedUserId;

  @override
  Future<List<AppTransaction>> fetchByMonth(String userId, String month) async {
    return [
      AppTransaction(
        id: 'tx-1',
        userId: userId,
        type: TransactionType.expense,
        amount: 1000,
        title: 'Lunch',
        occurredAt: DateTime(2026, 5, 31),
        createdAt: DateTime(2026, 5, 31),
      ),
    ];
  }

  @override
  Future<void> delete(String id, {String? userId}) async {
    deletedId = id;
    deletedUserId = userId;
  }
}

class _RecordingCategoryRepository extends CategoryRepository {
  String? deletedId;
  String? deletedUserId;

  @override
  Future<List<AppCategory>> fetchAll(String userId) async {
    return [
      AppCategory(
        id: 'cat-1',
        userId: userId,
        name: 'Food',
        type: 'expense',
        icon: 'category',
        colorHex: '#000000',
        isDefault: false,
        createdAt: DateTime(2026, 5, 31),
      ),
    ];
  }

  @override
  Future<void> delete(String id, {String? userId}) async {
    deletedId = id;
    deletedUserId = userId;
  }
}

class _RecordingFixedExpenseRepository extends FixedExpenseRepository {
  String? deletedId;
  String? deletedUserId;

  @override
  Future<List<FixedExpense>> fetchAll(String userId) async {
    return [
      FixedExpense(
        id: 'fixed-1',
        userId: userId,
        title: 'Rent',
        amount: 500000,
        cycle: 'monthly',
        billingDay: 1,
        isActive: true,
        createdAt: DateTime(2026, 5, 31),
        updatedAt: DateTime(2026, 5, 31),
      ),
    ];
  }

  @override
  Future<void> delete(String id, {String? userId}) async {
    deletedId = id;
    deletedUserId = userId;
  }
}

class _RecordingNotificationRepository extends NotificationRepository {
  String? deletedId;
  String? deletedUserId;

  @override
  Future<List<NotificationRule>> fetchRules(String userId) async {
    return [
      NotificationRule(
        id: 'rule-1',
        userId: userId,
        fixedExpenseId: 'fixed-1',
        title: 'Rent',
        isEnabled: true,
        remindDaysBefore: 1,
        remindAt: '09:00',
        createdAt: DateTime(2026, 5, 31),
        updatedAt: DateTime(2026, 5, 31),
      ),
    ];
  }

  @override
  Future<void> deleteRule(String id, {String? userId}) async {
    deletedId = id;
    deletedUserId = userId;
  }
}

void main() {
  test('TransactionProvider scopes delete by transaction owner', () async {
    final repo = _RecordingTransactionRepository();
    final provider = TransactionProvider(repo);

    await provider.loadMonth('user-1', DateTime(2026, 5, 31));
    await provider.deleteTransaction('tx-1');

    expect(repo.deletedId, 'tx-1');
    expect(repo.deletedUserId, 'user-1');
  });

  test('CategoryProvider scopes delete by category owner', () async {
    final repo = _RecordingCategoryRepository();
    final provider = CategoryProvider(repo);

    await provider.load('user-1');
    await provider.deleteCategory('cat-1');

    expect(repo.deletedId, 'cat-1');
    expect(repo.deletedUserId, 'user-1');
  });

  test('FixedExpenseProvider scopes delete by fixed expense owner', () async {
    final repo = _RecordingFixedExpenseRepository();
    final provider = FixedExpenseProvider(repo);

    await provider.load('user-1');
    await provider.remove('fixed-1');

    expect(repo.deletedId, 'fixed-1');
    expect(repo.deletedUserId, 'user-1');
  });

  test(
    'NotificationRuleProvider scopes delete by notification rule owner',
    () async {
      final repo = _RecordingNotificationRepository();
      final provider = NotificationRuleProvider(repo);

      await provider.load('user-1');
      await provider.removeForExpense('fixed-1');

      expect(repo.deletedId, 'rule-1');
      expect(repo.deletedUserId, 'user-1');
    },
  );
}
