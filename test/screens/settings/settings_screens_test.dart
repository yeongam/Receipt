import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:integrated_expense/data/models/app_user.dart';
import 'package:integrated_expense/data/models/category.dart';
import 'package:integrated_expense/data/repositories/auth_repository.dart';
import 'package:integrated_expense/data/repositories/category_repository.dart';
import 'package:integrated_expense/providers/auth_provider.dart';
import 'package:integrated_expense/providers/category_provider.dart';
import 'package:integrated_expense/providers/settings_provider.dart';
import 'package:integrated_expense/screens/settings/settings_screens.dart';

void main() {
  testWidgets('분류 관리 화면은 실제 카테고리를 보여주고 추가/삭제한다', (tester) async {
    final authProvider = AuthProvider(_FakeAuthRepository());
    await authProvider.signIn(email: 'user@example.com', password: 'pw');

    final categoryProvider = CategoryProvider(_FakeCategoryRepository());
    await categoryProvider.addCategory(
      AppCategory(
        id: 'coffee',
        userId: 'user-1',
        name: '커피',
        type: 'expense',
        icon: 'local_cafe',
        colorHex: '#6D4C41',
        isDefault: false,
        createdAt: DateTime(2026, 4, 29),
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<CategoryProvider>.value(
              value: categoryProvider),
          ChangeNotifierProvider(
              create: (_) => SettingsProvider(storage: _MemorySettingsStore())),
        ],
        child: const MaterialApp(
          home: CategorySettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('커피'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '간식');
    await tester.tap(find.text('추가').first);
    await tester.pumpAndSettle();

    expect(find.text('간식'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();

    expect(find.text('커피'), findsNothing);
  });

  testWidgets('분류 입력 중 목록이 갱신되어도 입력값을 유지한다', (tester) async {
    final authProvider = AuthProvider(_FakeAuthRepository());
    await authProvider.signIn(email: 'user@example.com', password: 'pw');

    final categoryProvider = CategoryProvider(_FakeCategoryRepository());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<CategoryProvider>.value(
              value: categoryProvider),
          ChangeNotifierProvider(
              create: (_) => SettingsProvider(storage: _MemorySettingsStore())),
        ],
        child: const MaterialApp(
          home: CategorySettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '간식');
    await categoryProvider.addCategory(
      AppCategory(
        id: 'transport',
        userId: 'user-1',
        name: '교통',
        type: 'expense',
        icon: 'directions_bus',
        colorHex: '#42A5F5',
        isDefault: true,
        createdAt: DateTime(2026, 4, 29),
      ),
    );
    await tester.pumpAndSettle();

    final input = tester.widget<TextField>(find.byType(TextField).first);
    expect(input.controller?.text, '간식');
  });
}

class _FakeAuthRepository extends AuthRepository {
  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    return AppUser(
      id: 'user-1',
      email: email,
      name: 'Tester',
      monthlyIncome: 2500000,
      currency: 'KRW',
      isProfileCompleted: true,
      createdAt: DateTime(2026, 4, 29),
      updatedAt: DateTime(2026, 4, 29),
    );
  }
}

class _FakeCategoryRepository extends CategoryRepository {
  int _nextId = 1;
  final Set<String> _deletedIds = {};

  @override
  Future<AppCategory> insert(AppCategory category) async {
    return AppCategory(
      id: category.id.isEmpty ? 'category-${_nextId++}' : category.id,
      userId: category.userId,
      name: category.name,
      type: category.type,
      icon: category.icon,
      colorHex: category.colorHex,
      isDefault: category.isDefault,
      createdAt: category.createdAt,
    );
  }

  @override
  Future<void> delete(String id) async {
    _deletedIds.add(id);
  }
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
