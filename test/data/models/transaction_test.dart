import 'package:flutter_test/flutter_test.dart';

import 'package:integrated_expense/data/models/transaction.dart';

void main() {
  test('거래 시각은 UTC로 저장된다', () {
    final localOccurredAt = DateTime(2026, 5, 1, 0, 30);
    final transaction = AppTransaction(
      id: '',
      userId: 'user-1',
      categoryId: 'category-1',
      type: TransactionType.expense,
      amount: 12000,
      title: '야식',
      occurredAt: localOccurredAt,
      createdAt: localOccurredAt,
    );

    final storedValue = transaction.toInsertMap()['occurred_at'] as String;
    final storedTime = DateTime.parse(storedValue);

    expect(storedTime.isUtc, isTrue);
    expect(storedTime.toLocal(), localOccurredAt);
  });

  test('UTC로 저장된 거래 시각은 읽을 때 로컬 시각으로 복원된다', () {
    final transaction = AppTransaction.fromMap({
      'id': 'tx-1',
      'user_id': 'user-1',
      'category_id': 'category-1',
      'type': 'expense',
      'amount': 12000,
      'title': '야식',
      'occurred_at': '2026-04-30T15:30:00.000Z',
      'created_at': '2026-04-30T15:30:00.000Z',
    });

    expect(transaction.occurredAt.isUtc, isFalse);
    expect(transaction.occurredAt.year, 2026);
    expect(transaction.occurredAt.month, 5);
    expect(transaction.occurredAt.day, 1);
    expect(transaction.occurredAt.hour, 0);
    expect(transaction.occurredAt.minute, 30);
  });
}
