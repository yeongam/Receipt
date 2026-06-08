import 'package:flutter_test/flutter_test.dart';
import 'package:integrated_expense/data/repositories/auth_repository.dart';

void main() {
  test('authEmailForUsername preserves existing simple ID email mapping', () {
    expect(
      AuthRepository.authEmailForUsername('user.name-01'),
      'user.name-01@receipt.app',
    );
  });

  test(
    'authEmailForUsername creates a valid deterministic email for IDs with @',
    () {
      final email = AuthRepository.authEmailForUsername('user@example');

      expect(email, isNot(contains('@example@')));
      expect(email, endsWith('@receipt.app'));
      expect(AuthRepository.authEmailForUsername('user@example'), email);
    },
  );
}
