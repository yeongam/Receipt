import 'package:flutter_test/flutter_test.dart';

import 'package:integrated_expense/main.dart';

void main() {
  testWidgets('shows a clear message when Supabase config is missing', (
    tester,
  ) async {
    await tester.pumpWidget(const MissingSupabaseConfigApp());

    expect(find.textContaining('Supabase 설정이 필요합니다'), findsOneWidget);
    expect(find.textContaining('SUPABASE_URL'), findsOneWidget);
    expect(find.textContaining('SUPABASE_ANON_KEY'), findsOneWidget);
  });
}
