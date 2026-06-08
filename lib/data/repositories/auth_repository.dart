import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_config.dart';
import '../models/app_user.dart';

class AuthRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  User? get currentAuthUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AppUser?> fetchProfile(String userId) async {
    final data = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;
    return AppUser.fromMap(data);
  }

  static String authEmailForUsername(String username) {
    final normalized = username.trim();
    if (!normalized.contains('@')) return '$normalized@receipt.app';

    final encoded = base64Url
        .encode(utf8.encode(normalized))
        .replaceAll('=', '');
    return 'u-$encoded@receipt.app';
  }

  Future<AppUser> signUp({
    required String username,
    required String password,
    String name = '',
    String recoveryKeyword = '',
    String? recoveryCodeHash,
  }) async {
    final response = await _client.auth.signUp(
      email: authEmailForUsername(username),
      password: password,
      data: {
        'username': username,
        'name': name,
        'recovery_keyword': recoveryKeyword,
      },
    );

    final user = response.user;
    if (user == null) {
      throw Exception('회원가입 실패: 사용자 정보를 받지 못했습니다.');
    }

    final userId = user.id;

    try {
      await _client.rpc(
        'seed_default_categories',
        params: {'p_user_id': userId},
      );
    } catch (e) {
      debugPrint('[AuthRepository] seed_default_categories failed: $e');
    }

    AppUser? profile;
    for (var i = 0; i < 5; i++) {
      await Future.delayed(Duration(milliseconds: 200 * (1 << i)));
      profile = await fetchProfile(userId);
      if (profile != null) break;
    }

    if (recoveryCodeHash != null && recoveryCodeHash.isNotEmpty) {
      try {
        await _client
            .from('users')
            .update({'app_lock_recovery_code': recoveryCodeHash})
            .eq('id', userId);
      } catch (e) {
        debugPrint('[AuthRepository] recovery code update failed: $e');
      }
    }

    final finalProfile = await fetchProfile(userId);
    if (finalProfile == null) throw Exception('프로필 생성에 실패했습니다.');
    return finalProfile;
  }

  Future<String?> findUsernameByRecovery({
    required String name,
    required String recoveryKeyword,
  }) async {
    try {
      final result = await _client.rpc(
        'find_username_by_recovery',
        params: {'p_name': name, 'p_recovery_keyword': recoveryKeyword},
      );
      return result as String?;
    } catch (e) {
      debugPrint('[AuthRepository] findUsernameByRecovery failed: $e');
      return null;
    }
  }

  Future<bool> resetPasswordWithRecovery({
    required String username,
    required String recoveryCode,
    required String newPassword,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'reset-password-with-recovery-code',
        body: {
          'username': username,
          'recoveryCode': recoveryCode,
          'newPassword': newPassword,
        },
      );
      return response.status == 200;
    } catch (e) {
      debugPrint('[AuthRepository] resetPasswordWithRecovery failed: $e');
      return false;
    }
  }

  Future<AppUser> signIn({
    required String username,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: authEmailForUsername(username),
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw Exception('로그인 실패: 이메일 또는 비밀번호를 확인하세요.');
    }

    final profile = await fetchProfile(user.id);
    if (profile == null) {
      throw Exception('사용자 프로필을 찾을 수 없습니다.');
    }
    return profile;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<AppUser> updateProfile(AppUser user) async {
    await _client.from('users').update(user.toUpdateMap()).eq('id', user.id);
    final profile = await fetchProfile(user.id);
    if (profile == null) throw Exception('프로필 업데이트 실패');
    return profile;
  }

  Future<AppUser> updateProfileFields(AppUser user) async {
    await _client
        .from('users')
        .update(user.toProfileUpdateMap())
        .eq('id', user.id);
    final profile = await fetchProfile(user.id);
    if (profile == null) throw Exception('프로필 업데이트 실패');
    return profile;
  }
}
