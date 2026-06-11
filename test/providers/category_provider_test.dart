import 'package:flutter_test/flutter_test.dart';

import 'package:integrated_expense/data/models/category.dart';
import 'package:integrated_expense/data/repositories/category_repository.dart';
import 'package:integrated_expense/providers/category_provider.dart';

void main() {
  test('카테고리 목록 getter는 내부 상태를 직접 수정할 수 없게 한다', () async {
    final provider = CategoryProvider(
      _FakeCategoryRepository(categories: [_category(id: 'category-1')]),
    );

    await provider.load('user-1');

    expect(
      () => provider.categories.add(_category(id: 'category-2')),
      throwsUnsupportedError,
    );
  });

  test('빈 사용자 id로 카테고리 조회를 요청하면 원격 호출하지 않는다', () async {
    final repository = _FakeCategoryRepository();
    final provider = CategoryProvider(repository);

    await provider.load(' ');

    expect(repository.fetchAllCallCount, 0);
    expect(provider.isLoading, isFalse);
  });

  test('빈 사용자 id 카테고리 추가는 저장소 호출 전에 실패한다', () async {
    final repository = _FakeCategoryRepository();
    final provider = CategoryProvider(repository);

    await expectLater(
      provider.addCategory(_category(id: '', userId: ' ')),
      throwsA(isA<StateError>()),
    );

    expect(repository.insertCallCount, 0);
  });
}

class _FakeCategoryRepository extends CategoryRepository {
  final List<AppCategory> categories;
  int fetchAllCallCount = 0;
  int insertCallCount = 0;

  _FakeCategoryRepository({this.categories = const []});

  @override
  Future<List<AppCategory>> fetchAll(String userId) async {
    fetchAllCallCount++;
    return categories;
  }

  @override
  Future<AppCategory> insert(AppCategory category) async {
    insertCallCount++;
    return category;
  }
}

AppCategory _category({required String id, String userId = 'user-1'}) {
  return AppCategory(
    id: id,
    userId: userId,
    name: '식비',
    type: 'expense',
    icon: 'restaurant',
    colorHex: '#FF7043',
    isDefault: false,
    createdAt: DateTime(2026, 5, 1),
  );
}
