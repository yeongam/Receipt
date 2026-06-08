import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_config.dart';
import '../models/fixed_expense.dart';

class FixedExpenseRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  Future<List<FixedExpense>> fetchAll(String userId) async {
    final data = await _client
        .from('fixed_expenses')
        .select()
        .eq('user_id', userId)
        .order('created_at');
    return (data as List).map((e) => FixedExpense.fromMap(e)).toList();
  }

  Future<List<FixedExpense>> fetchActive(String userId) async {
    final data = await _client
        .from('fixed_expenses')
        .select()
        .eq('user_id', userId)
        .eq('is_active', true)
        .order('billing_day');
    return (data as List).map((e) => FixedExpense.fromMap(e)).toList();
  }

  Future<FixedExpense> insert(FixedExpense fe) async {
    final data = await _client
        .from('fixed_expenses')
        .insert(fe.toInsertMap())
        .select()
        .single();
    return FixedExpense.fromMap(data);
  }

  Future<FixedExpense> update(FixedExpense fe) async {
    final map = fe.toInsertMap()..remove('user_id');
    final data = await _client
        .from('fixed_expenses')
        .update(map)
        .eq('id', fe.id)
        .eq('user_id', fe.userId)
        .select()
        .single();
    return FixedExpense.fromMap(data);
  }

  Future<void> delete(String id, {String? userId}) async {
    final effectiveUserId = userId ?? _client.auth.currentUser?.id;
    var query = _client.from('fixed_expenses').delete().eq('id', id);
    if (effectiveUserId != null && effectiveUserId.trim().isNotEmpty) {
      query = query.eq('user_id', effectiveUserId);
    }
    await query;
  }
}
