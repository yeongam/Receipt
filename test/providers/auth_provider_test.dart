import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:integrated_expense/data/models/app_user.dart';
import 'package:integrated_expense/data/repositories/auth_repository.dart';
import 'package:integrated_expense/providers/auth_provider.dart';

void main() {
  test('dispose cancels the auth state subscription', () {
    final repository = _FakeAuthRepository();
    final provider = AuthProvider(repository);

    provider.dispose();

    expect(repository.isCancelled, isTrue);
  });

  test('stale auth profile loads do not overwrite later sign-out', () async {
    final repository = _FakeAuthRepository();
    final provider = AuthProvider(repository);

    repository.emit(AuthState(AuthChangeEvent.signedIn, _session('user-1')));
    await Future<void>.delayed(Duration.zero);

    repository.emit(const AuthState(AuthChangeEvent.signedOut, null));
    await Future<void>.delayed(Duration.zero);
    expect(provider.status, AuthStatus.unauthenticated);

    repository.completeProfileFetch('user-1', _user('user-1'));
    await Future<void>.delayed(Duration.zero);

    expect(provider.status, AuthStatus.unauthenticated);
    expect(provider.user, isNull);
  });

  test('disposed provider ignores completed sign-in without notifying',
      () async {
    final repository = _FakeAuthRepository();
    final provider = AuthProvider(repository);

    final signIn = provider.signIn(
      username: 'user',
      password: 'password',
    );
    provider.dispose();
    repository.completeSignIn(_user('user-1'));

    await expectLater(signIn, completes);
  });
}

class _FakeAuthRepository extends AuthRepository {
  late final StreamController<AuthState> _controller =
      StreamController<AuthState>(onCancel: () {
    isCancelled = true;
  });

  bool isCancelled = false;
  final Map<String, Completer<AppUser?>> _profileFetches = {};
  Completer<AppUser>? _signIn;

  @override
  Stream<AuthState> get authStateChanges => _controller.stream;

  void emit(AuthState state) {
    _controller.add(state);
  }

  void completeProfileFetch(String userId, AppUser? user) {
    _profileFetches[userId]?.complete(user);
  }

  void completeSignIn(AppUser user) {
    _signIn?.complete(user);
  }

  @override
  Future<AppUser?> fetchProfile(String userId) {
    return (_profileFetches[userId] ??= Completer<AppUser?>()).future;
  }

  @override
  Future<AppUser> signIn({
    required String username,
    required String password,
  }) {
    _signIn = Completer<AppUser>();
    return _signIn!.future;
  }
}

Session _session(String userId) {
  return Session(
    accessToken: 'token',
    tokenType: 'bearer',
    user: User(
      id: userId,
      appMetadata: const {},
      userMetadata: const {},
      aud: 'authenticated',
      email: '$userId@example.com',
      createdAt: DateTime(2026, 5, 1).toIso8601String(),
    ),
  );
}

AppUser _user(String id) {
  return AppUser(
    id: id,
    username: id,
    name: 'Tester',
    monthlyIncome: 0,
    currency: 'KRW',
    isProfileCompleted: true,
    createdAt: DateTime(2026, 5, 1),
    updatedAt: DateTime(2026, 5, 1),
  );
}
