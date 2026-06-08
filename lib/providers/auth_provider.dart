import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/app_user.dart';
import '../data/repositories/auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo;
  late final StreamSubscription<AuthState> _authSubscription;
  bool _isDisposed = false;
  int _authEventVersion = 0;
  // signIn/signUp 진행 중 Supabase가 signedOut을 잠깐 발행하는 경우를 억제
  bool _isSigningIn = false;

  AuthStatus _status = AuthStatus.unknown;
  AppUser? _user;
  String? _errorMessage;

  AuthProvider(this._repo) {
    _authSubscription = _repo.authStateChanges.listen(_onAuthStateChange);
  }

  AuthStatus get status => _status;
  AppUser? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  void clearError() {
    _errorMessage = null;
    _notifyIfActive();
  }

  void _onAuthStateChange(AuthState state) async {
    final authUser = state.session?.user;

    // signIn/signUp 진행 중 Supabase가 일시적으로 signedOut을 발행하는 경우 무시
    if (_isSigningIn && authUser == null) return;

    final eventVersion = ++_authEventVersion;

    if (authUser == null) {
      _status = AuthStatus.unauthenticated;
      _user = null;
    } else {
      try {
        final profile = await _repo.fetchProfile(authUser.id);
        if (_isDisposed || eventVersion != _authEventVersion) return;
        if (profile != null) {
          _user = profile;
          _status = AuthStatus.authenticated;
        } else if (_status != AuthStatus.authenticated) {
          // 프로필 미존재 + 미인증 상태일 때만 unauthenticated로 전환
          _user = null;
          _status = AuthStatus.unauthenticated;
        }
        // 이미 authenticated인 경우 일시적 null을 무시 (레이스컨디션 방어)
      } catch (e) {
        if (_isDisposed || eventVersion != _authEventVersion) return;
        _errorMessage = e.toString();
        // 네트워크 오류 등 일시적 실패 시 기존 인증 상태 유지
        if (_status != AuthStatus.authenticated) {
          _user = null;
          _status = AuthStatus.unauthenticated;
        }
      }
    }
    _notifyIfActive();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _authSubscription.cancel();
    super.dispose();
  }

  Future<bool> signUp({
    required String username,
    required String password,
    String name = '',
    String recoveryKeyword = '',
    String recoveryCode = '',
  }) async {
    _errorMessage = null;
    _isSigningIn = true;
    try {
      String? recoveryCodeHash;
      if (recoveryCode.isNotEmpty) {
        final hash = sha256.convert(utf8.encode(recoveryCode)).toString();
        recoveryCodeHash = 'sha256:$hash';
      }
      final user = await _repo.signUp(
        username: username,
        password: password,
        name: name,
        recoveryKeyword: recoveryKeyword,
        recoveryCodeHash: recoveryCodeHash,
      );
      if (_isDisposed) return true;
      _authEventVersion++;
      _user = user;
      _status = AuthStatus.authenticated;
      _notifyIfActive();
      return true;
    } catch (e) {
      if (_isDisposed) return false;
      _errorMessage = e.toString();
      _notifyIfActive();
      return false;
    } finally {
      _isSigningIn = false;
    }
  }

  Future<String?> findUsernameByRecovery({
    required String name,
    required String recoveryKeyword,
  }) async {
    try {
      return await _repo.findUsernameByRecovery(
        name: name,
        recoveryKeyword: recoveryKeyword,
      );
    } catch (e) {
      _errorMessage = e.toString();
      _notifyIfActive();
      return null;
    }
  }

  Future<bool> resetPasswordWithRecovery({
    required String username,
    required String recoveryCode,
    required String newPassword,
  }) async {
    _errorMessage = null;
    try {
      return await _repo.resetPasswordWithRecovery(
        username: username,
        recoveryCode: recoveryCode,
        newPassword: newPassword,
      );
    } catch (e) {
      _errorMessage = e.toString();
      _notifyIfActive();
      return false;
    }
  }

  Future<bool> signIn({required String username, required String password}) async {
    _errorMessage = null;
    _isSigningIn = true;
    try {
      final user = await _repo.signIn(username: username, password: password);
      if (_isDisposed) return true;
      _authEventVersion++;
      _user = user;
      _status = AuthStatus.authenticated;
      _notifyIfActive();
      return true;
    } catch (e) {
      if (_isDisposed) return false;
      _errorMessage = e.toString();
      _notifyIfActive();
      return false;
    } finally {
      _isSigningIn = false;
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    if (_isDisposed) return;
    _authEventVersion++;
    _status = AuthStatus.unauthenticated;
    _user = null;
    _notifyIfActive();
  }

  Future<void> updateProfile(AppUser updated) async {
    try {
      final user = await _repo.updateProfile(updated);
      if (_isDisposed) return;
      _user = user;
      _notifyIfActive();
    } catch (e) {
      if (_isDisposed) return;
      _errorMessage = e.toString();
      _notifyIfActive();
    }
  }

  void _notifyIfActive() {
    if (!_isDisposed) notifyListeners();
  }
}
