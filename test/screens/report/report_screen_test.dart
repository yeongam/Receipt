import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:integrated_expense/data/models/transaction.dart';
import 'package:integrated_expense/data/repositories/category_repository.dart';
import 'package:integrated_expense/data/repositories/transaction_repository.dart';
import 'package:integrated_expense/providers/category_provider.dart';
import 'package:integrated_expense/providers/settings_provider.dart';
import 'package:integrated_expense/providers/transaction_provider.dart';
import 'package:integrated_expense/screens/report/report_screen.dart';

void main() {
  testWidgets('거래 데이터 변경 시 도넛 차트 painter가 다시 그려져야 한다', (tester) async {
    final transactionProvider =
        TransactionProvider(_FakeTransactionRepository());
    final categoryProvider = CategoryProvider(_FakeCategoryRepository());

    await transactionProvider.addTransaction(
      _expenseTransaction(amount: 12000),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: transactionProvider),
          ChangeNotifierProvider.value(value: categoryProvider),
          ChangeNotifierProvider(
            create: (_) => SettingsProvider(storage: _MemorySettingsStore()),
          ),
        ],
        child: const MaterialApp(
          home: ReportScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final donutChartFinder = find.byWidgetPredicate(
      (widget) =>
          widget is CustomPaint &&
          widget.painter != null &&
          widget.painter.runtimeType.toString() == '_DonutPainter',
    );

    final oldPainter = tester.widget<CustomPaint>(donutChartFinder).painter!;

    await transactionProvider.addTransaction(
      _expenseTransaction(amount: 18000),
    );
    await tester.pumpAndSettle();

    final newPainter = tester.widget<CustomPaint>(donutChartFinder).painter!;

    expect(newPainter.shouldRepaint(oldPainter), isTrue);
  });
}

AppTransaction _expenseTransaction({required int amount}) {
  final now = DateTime.now();
  return AppTransaction(
    id: '',
    userId: 'user-1',
    categoryId: 'category-1',
    type: TransactionType.expense,
    amount: amount,
    title: 'expense-$amount',
    occurredAt: now,
    createdAt: now,
  );
}

class _FakeTransactionRepository extends TransactionRepository {
  int _nextId = 1;

  @override
  Future<AppTransaction> insert(AppTransaction tx) async {
    return AppTransaction(
      id: 'tx-${_nextId++}',
      userId: tx.userId,
      categoryId: tx.categoryId,
      fixedExpenseId: tx.fixedExpenseId,
      type: tx.type,
      amount: tx.amount,
      title: tx.title,
      memo: tx.memo,
      occurredAt: tx.occurredAt,
      createdAt: tx.createdAt,
    );
  }
}

class _FakeCategoryRepository extends CategoryRepository {}

class _MemorySettingsStore implements SettingsStore {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }
}
