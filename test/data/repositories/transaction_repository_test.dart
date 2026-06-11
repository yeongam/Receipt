import 'package:flutter_test/flutter_test.dart';

import 'package:integrated_expense/data/repositories/transaction_repository.dart';

void main() {
  test('월 조회 범위는 로컬 월 경계를 UTC 기준으로 변환한다', () {
    final range = buildMonthQueryRange('2026-05');

    expect(range.startUtc, DateTime.utc(2026, 4, 30, 15));
    expect(range.endExclusiveUtc, DateTime.utc(2026, 5, 31, 15));
  });
}
