import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('seed_default_categories RPC is limited to the authenticated owner', () {
    final migration =
        File('supabase/migrations/20260429000000_initial_schema.sql')
            .readAsStringSync();

    expect(migration, contains('auth.uid() <> p_user_id'));
    expect(
      migration,
      contains(
        'revoke execute on function public.seed_default_categories(uuid) from public',
      ),
    );
    expect(
      migration,
      contains(
        'grant execute on function public.seed_default_categories(uuid) to authenticated',
      ),
    );
  });

  test('tenant-owned foreign references are validated in database triggers',
      () {
    final migration =
        File('supabase/migrations/20260429000000_initial_schema.sql')
            .readAsStringSync();

    expect(migration, contains('ensure_transaction_owned_refs'));
    expect(migration, contains('ensure_fixed_expense_owned_refs'));
    expect(migration, contains('ensure_budget_category_owned_refs'));
    expect(migration, contains('ensure_notification_rule_owned_refs'));
  });

  test('updated_at columns are maintained by update triggers', () {
    final migration =
        File('supabase/migrations/20260429000000_initial_schema.sql')
            .readAsStringSync();

    expect(migration, contains('set_updated_at'));
    expect(migration, contains('set_users_updated_at'));
    expect(migration, contains('set_transactions_updated_at'));
    expect(migration, contains('set_notification_rules_updated_at'));
  });

  test('owned reference triggers avoid update-of syntax for SQL editor compatibility',
      () {
    final migration = File('supabase/migrations/20260429000000_initial_schema.sql')
        .readAsStringSync();

    expect(migration.toLowerCase(), isNot(contains('update of')));
  });
}
