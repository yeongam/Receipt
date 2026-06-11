import 'package:flutter_test/flutter_test.dart';

import 'package:integrated_expense/data/models/transaction.dart';
import 'package:integrated_expense/data/repositories/transaction_repository.dart';
import 'package:integrated_expense/providers/transaction_provider.dart';

void main() {
  test('거래 추가 후 월별 추이가 즉시 갱신된다', () async {
    final repository = _FakeTransactionRepository();
    final provider = TransactionProvider(repository);

    await provider.loadMonthlyTrends('user-1', count: 1);
    expect(provider.monthlyTrends.single.expense, 0);

    await provider.addTransaction(
      _transaction(
        id: '',
        amount: 25000,
        occurredAt: DateTime.now(),
      ),
    );

    expect(provider.monthlyTrends.single.expense, 25000);
  });

  test('히스토리용 월 조회는 현재 선택 월을 바꾸지 않고 월별 캐시를 유지한다', () async {
    final repository = _FakeTransactionRepository(
      initialItems: [
        _transaction(
          id: 'current-month',
          amount: 15000,
          occurredAt: DateTime(2026, 5, 10),
        ),
        _transaction(
          id: 'previous-month',
          amount: 23000,
          occurredAt: DateTime(2026, 4, 12),
        ),
      ],
    );
    final provider = TransactionProvider(repository);

    final currentMonth = DateTime(2026, 5);
    final previousMonth = DateTime(2026, 4);

    await provider.loadMonth('user-1', currentMonth);
    await provider.loadMonth('user-1', previousMonth, select: false);

    expect(provider.selectedMonth, currentMonth);
    expect(provider.totalExpenseForMonth(currentMonth), 15000);
    expect(provider.totalExpenseForMonth(previousMonth), 23000);
  });

  test('다른 월을 둘러본 뒤 현재 월 거래를 추가해도 이전 월 집계는 오염되지 않는다', () async {
    final repository = _FakeTransactionRepository(
      initialItems: [
        _transaction(
          id: 'current-month',
          amount: 15000,
          occurredAt: DateTime(2026, 5, 10),
        ),
        _transaction(
          id: 'previous-month',
          amount: 23000,
          occurredAt: DateTime(2026, 4, 12),
        ),
      ],
    );
    final provider = TransactionProvider(repository);

    final currentMonth = DateTime(2026, 5);
    final previousMonth = DateTime(2026, 4);

    await provider.loadMonth('user-1', currentMonth);
    await provider.loadMonth('user-1', previousMonth, select: false);
    await provider.addTransaction(
      _transaction(
        id: '',
        amount: 9000,
        occurredAt: DateTime(2026, 5, 28),
      ),
    );

    expect(provider.totalExpenseForMonth(currentMonth), 24000);
    expect(provider.totalExpenseForMonth(previousMonth), 23000);
  });

  test('빈 사용자 id로 월 조회를 요청하면 원격 호출하지 않는다', () async {
    final repository = _FakeTransactionRepository();
    final provider = TransactionProvider(repository);
    final initialMonth = provider.selectedMonth;

    await provider.loadMonth('', DateTime(2026, 5));

    expect(repository.fetchByMonthCallCount, 0);
    expect(provider.selectedMonth, initialMonth);
    expect(provider.isLoading, isFalse);
  });

  test('빈 사용자 id 거래 추가는 저장소 호출 전에 실패한다', () async {
    final repository = _FakeTransactionRepository();
    final provider = TransactionProvider(repository);

    await expectLater(
      provider.addTransaction(
        _transaction(
          id: '',
          userId: '',
          amount: 1000,
          occurredAt: DateTime(2026, 5, 10),
        ),
      ),
      throwsA(isA<StateError>()),
    );
    expect(repository.insertCallCount, 0);
  });

  test('사용자 전환 시 이전 사용자 캐시가 새 사용자에 노출되지 않는다', () async {
    // user-1 loads a month with data, then we switch to user-2.
    // user-2 must see an empty list, not user-1's transactions.
    final repository = _FakeTransactionRepository(
      initialItems: [
        _transaction(
          id: 'user1-tx',
          userId: 'user-1',
          amount: 50000,
          occurredAt: DateTime(2026, 5, 10),
        ),
      ],
    );
    final provider = TransactionProvider(repository);
    final may2026 = DateTime(2026, 5);

    await provider.loadMonth('user-1', may2026);
    expect(provider.totalExpenseForMonth(may2026), 50000);

    // Simulate sign-out / user switch.
    provider.clear();

    await provider.loadMonth('user-2', may2026);

    // user-2 has no transactions; must not see user-1's data.
    expect(provider.totalExpenseForMonth(may2026), 0);
  });

  test('loadMonth 진행 중 clear()를 호출하면 완료 후 캐시에 쓰지 않는다', () async {
    // Arrange: repository responds after a small delay so we can interleave clear().
    final repository = _DelayedTransactionRepository(
      delay: const Duration(milliseconds: 20),
      items: [
        _transaction(
          id: 'stale-tx',
          userId: 'user-1',
          amount: 99000,
          occurredAt: DateTime(2026, 5, 10),
        ),
      ],
    );
    final provider = TransactionProvider(repository);
    final may2026 = DateTime(2026, 5);

    // Start loading but don't await yet.
    final loadFuture = provider.loadMonth('user-1', may2026);

    // Immediately clear (simulates sign-out while fetch is in-flight).
    provider.clear();

    // Wait for the fetch to complete.
    await loadFuture;

    // The stale write must not have happened after clear().
    expect(provider.totalExpenseForMonth(may2026), 0);
    expect(provider.isLoading, isFalse);
  });

  test('addTransaction과 loadMonthlyTrends 동시 실행 시 새 거래가 누락되지 않는다', () async {
    final repository = _FakeTransactionRepository();
    final provider = TransactionProvider(repository);

    await provider.loadMonth('user-1', DateTime(2026, 5));

    // Run both operations concurrently.
    await Future.wait([
      provider.addTransaction(
        _transaction(
          id: '',
          amount: 15000,
          occurredAt: DateTime(2026, 5, 15),
        ),
      ),
      provider.loadMonthlyTrends('user-1', count: 1),
    ]);

    expect(provider.monthlyTrends.single.expense, 15000);
  });
}

class _FakeTransactionRepository extends TransactionRepository {
  final List<AppTransaction> _items;
  int _nextId = 1;
  int fetchByMonthCallCount = 0;
  int insertCallCount = 0;

  _FakeTransactionRepository({List<AppTransaction> initialItems = const []})
      : _items = List<AppTransaction>.from(initialItems);

  @override
  Future<List<AppTransaction>> fetchByMonth(String userId, String month) async {
    fetchByMonthCallCount++;
    return _items
        .where((transaction) =>
            transaction.userId == userId &&
            '${transaction.occurredAt.year}-${transaction.occurredAt.month.toString().padLeft(2, '0')}' ==
                month)
        .toList();
  }

  @override
  Future<AppTransaction> insert(AppTransaction tx) async {
    insertCallCount++;
    final created = _transaction(
      id: 'tx-${_nextId++}',
      userId: tx.userId,
      amount: tx.amount,
      occurredAt: tx.occurredAt,
    );
    _items.add(created);
    return created;
  }
}

/// Repository that introduces an artificial [delay] before returning results,
/// enabling tests to interleave concurrent operations.
class _DelayedTransactionRepository extends TransactionRepository {
  final Duration delay;
  final List<AppTransaction> items;

  _DelayedTransactionRepository({required this.delay, required this.items});

  @override
  Future<List<AppTransaction>> fetchByMonth(String userId, String month) async {
    await Future<void>.delayed(delay);
    return items
        .where((t) =>
            t.userId == userId &&
            '${t.occurredAt.year}-${t.occurredAt.month.toString().padLeft(2, '0')}' ==
                month)
        .toList();
  }
}

AppTransaction _transaction({
  required String id,
  String userId = 'user-1',
  required int amount,
  required DateTime occurredAt,
}) {
  return AppTransaction(
    id: id,
    userId: userId,
    categoryId: 'category-1',
    type: TransactionType.expense,
    amount: amount,
    title: '지출',
    occurredAt: occurredAt,
    createdAt: occurredAt,
  );
}
