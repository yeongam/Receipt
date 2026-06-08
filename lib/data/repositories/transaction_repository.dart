import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_config.dart';
import '../models/transaction.dart';

typedef TransactionMonthQueryRange = ({
  DateTime startUtc,
  DateTime endExclusiveUtc,
});

TransactionMonthQueryRange buildMonthQueryRange(String month) {
  final parts = month.split('-');
  final year = int.parse(parts[0]);
  final mon = int.parse(parts[1]);
  final startUtc = DateTime(year, mon, 1).toUtc();
  final endExclusiveUtc = DateTime(year, mon + 1, 1).toUtc();
  return (startUtc: startUtc, endExclusiveUtc: endExclusiveUtc);
}

class TransactionRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  Future<List<AppTransaction>> fetchByMonth(String userId, String month) async {
    final range = buildMonthQueryRange(month);
    final data = await _client
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .gte('occurred_at', range.startUtc.toIso8601String())
        .lt('occurred_at', range.endExclusiveUtc.toIso8601String())
        .order('occurred_at', ascending: false);
    return (data as List).map((e) => AppTransaction.fromMap(e)).toList();
  }

  Future<List<AppTransaction>> fetchAll(String userId) async {
    final data = await _client
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .order('occurred_at', ascending: false);
    return (data as List).map((e) => AppTransaction.fromMap(e)).toList();
  }

  Future<AppTransaction> insert(AppTransaction tx) async {
    final data = await _client
        .from('transactions')
        .insert(tx.toInsertMap())
        .select()
        .single();
    return AppTransaction.fromMap(data);
  }

  Future<AppTransaction> update(AppTransaction tx) async {
    final map = tx.toInsertMap()..remove('user_id');
    final data = await _client
        .from('transactions')
        .update(map)
        .eq('id', tx.id)
        .eq('user_id', tx.userId)
        .select()
        .single();
    return AppTransaction.fromMap(data);
  }

  Future<void> delete(String id, {String? userId}) async {
    final effectiveUserId = userId ?? _client.auth.currentUser?.id;
    var query = _client.from('transactions').delete().eq('id', id);
    if (effectiveUserId != null && effectiveUserId.trim().isNotEmpty) {
      query = query.eq('user_id', effectiveUserId);
    }
    await query;
  }
}
