import 'package:flutter_test/flutter_test.dart';

import 'package:integrated_expense/data/models/category.dart';
import 'package:integrated_expense/data/models/transaction.dart';
import 'package:integrated_expense/screens/shared/transaction_entry_sheet.dart';

void main() {
  test('거래 초안 생성 시 선택한 분류의 categoryId가 저장된다', () {
    final category = AppCategory(
      id: 'category-food',
      userId: 'user-1',
      name: '식비',
      type: 'expense',
      icon: 'fork',
      colorHex: '#FF8A65',
      isDefault: true,
      createdAt: DateTime(2026, 4, 29),
    );
    final now = DateTime(2026, 4, 29, 10, 30);

    final transaction = createTransactionDraft(
      userId: 'user-1',
      type: TransactionType.expense,
      title: '점심',
      amount: 12000,
      category: category,
      now: now,
    );

    expect(transaction.categoryId, 'category-food');
    expect(transaction.title, '점심');
    expect(transaction.amount, 12000);
    expect(transaction.occurredAt, now);
  });
}
