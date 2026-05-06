import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_config.dart';
import '../models/budget.dart';

class BudgetRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  Future<Budget?> fetchByMonth(String userId, String month) async {
    final data = await _client
        .from('budgets')
        .select()
        .eq('user_id', userId)
        .eq('month', month)
        .maybeSingle();
    if (data == null) return null;
    return Budget.fromMap(data);
  }

  Future<Budget> upsert(Budget budget) async {
    final data = await _client
        .from('budgets')
        .upsert(budget.toInsertMap(), onConflict: 'user_id,month')
        .select()
        .single();
    return Budget.fromMap(data);
  }

  Future<List<BudgetCategory>> fetchCategoriesByMonth(
      String userId, String month) async {
    final data = await _client
        .from('budget_categories')
        .select()
        .eq('user_id', userId)
        .eq('month', month);
    return (data as List).map((e) => BudgetCategory.fromMap(e)).toList();
  }

  Future<BudgetCategory> upsertCategory(BudgetCategory bc) async {
    final data = await _client
        .from('budget_categories')
        .upsert(bc.toInsertMap(), onConflict: 'user_id,month,category_id')
        .select()
        .single();
    return BudgetCategory.fromMap(data);
  }

  Future<void> deleteCategoryBudget(String id) async {
    await _client.from('budget_categories').delete().eq('id', id);
  }
}
