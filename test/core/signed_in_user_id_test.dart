import 'package:flutter_test/flutter_test.dart';
import 'package:integrated_expense/core/auth/signed_in_user_id.dart';

void main() {
  test('auth provider user id takes precedence over fallback user id', () {
    expect(
      firstSignedInUserId(
        authProviderUserId: ' auth-user ',
        supabaseUserId: 'supabase-user',
      ),
      'auth-user',
    );
  });

  test('fallback user id is used when auth provider user id is blank', () {
    expect(
      firstSignedInUserId(
        authProviderUserId: ' ',
        supabaseUserId: ' supabase-user ',
      ),
      'supabase-user',
    );
  });

  test('blank user ids resolve to null', () {
    expect(
      firstSignedInUserId(authProviderUserId: '', supabaseUserId: ' '),
      isNull,
    );
  });
}
