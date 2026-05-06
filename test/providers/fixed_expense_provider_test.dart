import 'package:flutter_test/flutter_test.dart';

import 'package:integrated_expense/data/models/fixed_expense.dart';
import 'package:integrated_expense/data/repositories/fixed_expense_repository.dart';
import 'package:integrated_expense/providers/fixed_expense_provider.dart';

void main() {
  test('고정지출 목록 getter는 내부 상태를 직접 수정할 수 없게 한다', () async {
    final provider = FixedExpenseProvider(
      _FakeFixedExpenseRepository(items: [_fixedExpense(id: 'fixed-1')]),
    );

    await provider.load('user-1');

    expect(
      () => provider.items.add(_fixedExpense(id: 'fixed-2')),
      throwsUnsupportedError,
    );
  });

  test('빈 사용자 id로 고정지출 조회를 요청하면 원격 호출하지 않는다', () async {
    final repository = _FakeFixedExpenseRepository();
    final provider = FixedExpenseProvider(repository);

    await provider.load('');

    expect(repository.fetchAllCallCount, 0);
    expect(provider.isLoading, isFalse);
  });

  test('빈 사용자 id 고정지출 추가는 저장소 호출 전에 실패한다', () async {
    final repository = _FakeFixedExpenseRepository();
    final provider = FixedExpenseProvider(repository);

    await expectLater(
      provider.add(_fixedExpense(id: '', userId: ' ')),
      throwsA(isA<StateError>()),
    );

    expect(repository.insertCallCount, 0);
  });

  test('빈 사용자 id 고정지출 수정은 저장소 호출 전에 실패한다', () async {
    final repository = _FakeFixedExpenseRepository();
    final provider = FixedExpenseProvider(repository);

    await expectLater(
      provider.edit(_fixedExpense(id: 'fixed-1', userId: '')),
      throwsA(isA<StateError>()),
    );

    expect(repository.updateCallCount, 0);
  });
}

class _FakeFixedExpenseRepository extends FixedExpenseRepository {
  final List<FixedExpense> items;
  int fetchAllCallCount = 0;
  int insertCallCount = 0;
  int updateCallCount = 0;

  _FakeFixedExpenseRepository({this.items = const []});

  @override
  Future<List<FixedExpense>> fetchAll(String userId) async {
    fetchAllCallCount++;
    return items;
  }

  @override
  Future<FixedExpense> insert(FixedExpense fe) async {
    insertCallCount++;
    return fe;
  }

  @override
  Future<FixedExpense> update(FixedExpense fe) async {
    updateCallCount++;
    return fe;
  }
}

FixedExpense _fixedExpense({required String id, String userId = 'user-1'}) {
  return FixedExpense(
    id: id,
    userId: userId,
    title: '월세',
    amount: 850000,
    cycle: 'monthly',
    billingDay: 25,
    isActive: true,
    createdAt: DateTime(2026, 5, 1),
    updatedAt: DateTime(2026, 5, 1),
  );
}
