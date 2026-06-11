import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:integrated_expense/data/models/category.dart';
import 'package:integrated_expense/data/repositories/category_repository.dart';
import 'package:integrated_expense/providers/category_provider.dart';
import 'package:integrated_expense/providers/settings_provider.dart';
import 'package:integrated_expense/screens/settings/settings_screens.dart';

void main() {
  testWidgets('분류 관리 화면은 실제 카테고리 저장소 데이터를 보여준다', (tester) async {
    final categoryProvider = CategoryProvider(
      _FakeCategoryRepository(
        categories: [
          AppCategory(
            id: 'expense-custom',
            userId: 'user-1',
            name: '커스텀지출',
            type: 'expense',
            icon: 'wallet',
            colorHex: '#123456',
            isDefault: false,
            createdAt: DateTime(2026, 4, 29),
          ),
          AppCategory(
            id: 'income-custom',
            userId: 'user-1',
            name: '커스텀수입',
            type: 'income',
            icon: 'wallet',
            colorHex: '#654321',
            isDefault: false,
            createdAt: DateTime(2026, 4, 29),
          ),
        ],
      ),
    );
    await categoryProvider.load('user-1');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: categoryProvider),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ],
        child: const MaterialApp(
          home: CategorySettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('커스텀지출'), findsOneWidget);
    expect(find.text('커스텀수입'), findsOneWidget);
    expect(find.text('생활'), findsNothing);
    expect(find.text('기타수입'), findsNothing);
  });
}

class _FakeCategoryRepository extends CategoryRepository {
  final List<AppCategory> categories;

  _FakeCategoryRepository({required this.categories});

  @override
  Future<List<AppCategory>> fetchAll(String userId) async => categories;
}
