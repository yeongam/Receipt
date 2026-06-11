import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:integrated_expense/data/models/category.dart';
import 'package:integrated_expense/data/models/transaction.dart';
import 'package:integrated_expense/data/repositories/category_repository.dart';
import 'package:integrated_expense/data/repositories/transaction_repository.dart';
import 'package:integrated_expense/providers/category_provider.dart';
import 'package:integrated_expense/providers/settings_provider.dart';
import 'package:integrated_expense/providers/transaction_provider.dart';
import 'package:integrated_expense/screens/shared/transaction_entry_sheet.dart';

void main() {
  testWidgets('로그인 사용자가 없으면 거래 저장소를 호출하지 않고 안내한다', (tester) async {
    final transactionRepository = _FakeTransactionRepository();
    final categoryProvider = CategoryProvider(_FakeCategoryRepository());
    await categoryProvider.addCategory(
      AppCategory(
        id: 'food',
        userId: 'user-1',
        name: '식비',
        type: 'expense',
        icon: 'restaurant',
        colorHex: '#FF7043',
        isDefault: true,
        createdAt: DateTime(2026, 5, 4),
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => TransactionProvider(transactionRepository),
          ),
          ChangeNotifierProvider.value(value: categoryProvider),
          ChangeNotifierProvider(
            create: (_) => SettingsProvider(storage: _MemorySettingsStore()),
          ),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () => openTransactionEntrySheet(
                    context,
                    TransactionType.expense,
                  ),
                  child: const Text('open'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '예: 점심, 교통비'), '점심');
    await tester.enterText(find.widgetWithText(TextField, '숫자만 입력'), '12000');
    await tester.tap(find.text('출금 저장'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(transactionRepository.insertCallCount, 0);
    expect(find.text('로그인이 필요합니다.'), findsOneWidget);
  });
}

class _FakeTransactionRepository extends TransactionRepository {
  int insertCallCount = 0;

  @override
  Future<AppTransaction> insert(AppTransaction tx) async {
    insertCallCount++;
    return tx;
  }
}

class _FakeCategoryRepository extends CategoryRepository {
  @override
  Future<AppCategory> insert(AppCategory category) async => category;
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
