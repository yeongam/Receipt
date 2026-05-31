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
    final eventVersion = ++_authEventVersion;
    final authUser = state.session?.user;
    if (authUser == null) {
      _status = AuthStatus.unauthenticated;
      _user = null;
    } else {
      try {
        final profile = await _repo.fetchProfile(authUser.id);
        if (_isDisposed || eventVersion != _authEventVersion) return;
        _user = profile;
        _status = profile != null
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated;
      } catch (e) {
        if (_isDisposed || eventVersion != _authEventVersion) return;
        _user = null;
        _status = AuthStatus.unauthenticated;
        _errorMessage = e.toString();
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
      _user = user;
      _status = AuthStatus.authenticated;
      _notifyIfActive();
      return true;
    } catch (e) {
      if (_isDisposed) return false;
      _errorMessage = e.toString();
      _notifyIfActive();
      return false;
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
    try {
      final user = await _repo.signIn(username: username, password: password);
      if (_isDisposed) return true;
      _user = user;
      _status = AuthStatus.authenticated;
      _notifyIfActive();
      return true;
    } catch (e) {
      if (_isDisposed) return false;
      _errorMessage = e.toString();
      _notifyIfActive();
      return false;
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
