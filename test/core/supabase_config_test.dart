import 'package:flutter_test/flutter_test.dart';
import 'package:integrated_expense/core/supabase/supabase_config.dart';

void main() {
  test('Supabase credentials are supplied by dart-define instead of source',
      () {
    expect(SupabaseConfig.url, isEmpty);
    expect(SupabaseConfig.anonKey, isEmpty);
    expect(SupabaseConfig.isConfigured, isFalse);
    expect(SupabaseConfig.requireConfigured, throwsA(isA<StateError>()));
  });
}
