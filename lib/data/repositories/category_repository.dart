import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_config.dart';
import '../models/category.dart';

class CategoryRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  Future<List<AppCategory>> fetchAll(String userId) async {
    final data = await _client
        .from('categories')
        .select()
        .eq('user_id', userId)
        .order('created_at');
    return (data as List).map((e) => AppCategory.fromMap(e)).toList();
  }

  Future<List<AppCategory>> fetchByType(String userId, String type) async {
    final data = await _client
        .from('categories')
        .select()
        .eq('user_id', userId)
        .eq('type', type)
        .order('created_at');
    return (data as List).map((e) => AppCategory.fromMap(e)).toList();
  }

  Future<AppCategory> insert(AppCategory category) async {
    final data = await _client
        .from('categories')
        .insert(category.toInsertMap())
        .select()
        .single();
    return AppCategory.fromMap(data);
  }

  Future<void> delete(String id) async {
    await _client.from('categories').delete().eq('id', id);
  }
}
