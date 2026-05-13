import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_config.dart';
import '../models/app_user.dart';

class AuthRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  User? get currentAuthUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AppUser?> fetchProfile(String userId) async {
    final data =
        await _client.from('users').select().eq('id', userId).maybeSingle();
    if (data == null) return null;
    return AppUser.fromMap(data);
  }

  Future<AppUser> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );

    final user = response.user;
    if (user == null) {
      throw Exception('회원가입 실패: 사용자 정보를 받지 못했습니다.\n이메일 인증이 필요한 경우 메일함을 확인하세요.');
    }

    final userId = user.id;

    // trigger가 users 프로필을 생성할 시간을 주기 위해 잠시 대기
    await Future.delayed(const Duration(milliseconds: 500));

    // seed default categories
    try {
      await _client
          .rpc('seed_default_categories', params: {'p_user_id': userId});
    } catch (_) {
      // 이미 카테고리가 있거나 실패해도 계속 진행
    }

    // update name in profile
    try {
      await _client.from('users').update({'name': name}).eq('id', userId);
    } catch (_) {}

    final profile = await fetchProfile(userId);
    if (profile == null) {
      throw Exception('프로필 생성에 실패했습니다. SQL 마이그레이션이 실행됐는지 확인하세요.');
    }
    return profile;
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
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

  /// Full update — includes app_lock security fields.
  /// Use only for setAppLockPasscode / disableAppLock paths.
  Future<AppUser> updateProfile(AppUser user) async {
    await _client.from('users').update(user.toUpdateMap()).eq('id', user.id);
    final profile = await fetchProfile(user.id);
    if (profile == null) throw Exception('프로필 업데이트 실패');
    return profile;
  }

  /// Profile-only update — excludes app_lock security fields.
  /// Use for all routine settings changes to avoid accidentally overwriting
  /// the PIN hash or recovery code stored in Supabase.
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
