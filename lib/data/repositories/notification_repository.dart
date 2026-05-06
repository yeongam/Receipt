import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_config.dart';
import '../models/notification_setting.dart';
import '../models/notification_rule.dart';

class NotificationRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  Future<NotificationSetting?> fetchSetting(String userId) async {
    final data = await _client
        .from('notification_settings')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (data == null) return null;
    return NotificationSetting.fromMap(data);
  }

  Future<NotificationSetting> updateSetting(NotificationSetting setting) async {
    final data = await _client
        .from('notification_settings')
        .upsert(
          {
            'user_id': setting.userId,
            ...setting.toUpdateMap(),
          },
          onConflict: 'user_id',
        )
        .select()
        .single();
    return NotificationSetting.fromMap(data);
  }

  Future<List<NotificationRule>> fetchRules(String userId) async {
    final data = await _client
        .from('notification_rules')
        .select()
        .eq('user_id', userId)
        .order('created_at');
    return (data as List).map((e) => NotificationRule.fromMap(e)).toList();
  }

  Future<NotificationRule> insertRule(NotificationRule rule) async {
    final data = await _client
        .from('notification_rules')
        .insert(rule.toInsertMap())
        .select()
        .single();
    return NotificationRule.fromMap(data);
  }

  Future<void> deleteRule(String id) async {
    await _client.from('notification_rules').delete().eq('id', id);
  }
}
