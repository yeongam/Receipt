import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Locale;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../data/models/app_user.dart';
import '../data/models/budget.dart';
import '../data/models/notification_setting.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/budget_repository.dart';
import '../data/repositories/notification_repository.dart';

String _doPbkdf2(List<String> args) =>
    SettingsProvider._pbkdf2(args[0], args[1]);

abstract class SettingsStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class SecureSettingsStore implements SettingsStore {
  SecureSettingsStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
}

class SettingsProvider extends ChangeNotifier {
  SettingsProvider({
    AuthRepository? authRepository,
    BudgetRepository? budgetRepository,
    NotificationRepository? notificationRepository,
    SettingsStore? storage,
  }) : _authRepository = authRepository,
       _budgetRepository = budgetRepository,
       _notificationRepository = notificationRepository,
       _storage = storage ?? SecureSettingsStore() {
    _pendingWork = _loadFromStorage();
  }

  static const String _storageKey = 'settings.v1';

  static int navigationIndexFor(String startScreen) {
    return switch (startScreen) {
      '홈' => 0,
      '내역' => 1,
      '리포트' => 2,
      '알림' => 3,
      '마이' => 4,
      _ => 0,
    };
  }

  final AuthRepository? _authRepository;
  final BudgetRepository? _budgetRepository;
  final NotificationRepository? _notificationRepository;
  final SettingsStore _storage;

  Future<void> _pendingWork = Future.value();
  AppUser? _user;
  String? _pendingRecoveryCode;
  NotificationSetting? _notificationSetting;
  bool _isLoaded = false;

  int _monthlyBudget = 2000000;
  int _budgetWarningPrimary = 80;
  int _budgetWarningSecondary = 100;
  String _budgetStartDay = '매월 1일';

  bool _budgetAlert = true;
  bool _fixedExpenseAlert = true;
  bool _reminderAlert = false;

  String _language = '한국어';
  String _currency = 'KRW';
  bool _compactView = false;
  bool _showWeeklySummary = true;
  String _themeLabel = '라이트';
  String _startScreen = '홈';

  bool _lockOnLaunch = false;
  bool _biometric = false;

  bool _hasPersistedMonthlyBudget = false;
  bool _hasPersistedCurrency = false;

  int get monthlyBudget => _monthlyBudget;
  int get budgetWarningPrimary => _budgetWarningPrimary;
  int get budgetWarningSecondary => _budgetWarningSecondary;
  String get budgetStartDay => _budgetStartDay;

  bool get budgetAlert => _budgetAlert;
  bool get fixedExpenseAlert => _fixedExpenseAlert;
  bool get reminderAlert => _reminderAlert;

  String get language => _language;
  bool get isEnglish => _language == 'English';
  Locale get locale => Locale(_language == 'English' ? 'en' : 'ko');
  String get currency => _currency;
  bool get compactView => _compactView;
  bool get showWeeklySummary => _showWeeklySummary;
  String get themeLabel => _themeLabel;

  String get themeToken => (_themeLabel == '다크' || _themeLabel == 'dark') ? 'dark' : 'light';

  String get startScreen => _startScreen;

  bool get lockOnLaunch => _lockOnLaunch;
  bool get biometric => _biometric;
  NotificationSetting? get notificationSetting => _notificationSetting;

  bool get hasAppLock => _user?.appLockPasscodeHash?.isNotEmpty == true;

  String? consumeRecoveryCode() {
    final code = _pendingRecoveryCode;
    _pendingRecoveryCode = null;
    return code;
  }

  Future<bool> validateAppLockPasscode(String passcode) async {
    final stored = _user?.appLockPasscodeHash;
    if (stored == null || stored.isEmpty) return false;
    if (stored.startsWith('pbkdf2:')) {
      final parts = stored.split(':');
      if (parts.length != 3) return false;
      final derived = await compute(_doPbkdf2, [passcode, parts[1]]);
      return _timingSafeEquals(derived, parts[2]);
    }
    if (stored.contains(':')) {
      final idx = stored.indexOf(':');
      final salt = stored.substring(0, idx);
      final hash = stored.substring(idx + 1);
      return _timingSafeEquals(_sha256(salt + passcode), hash);
    }
    return _timingSafeEquals(_sha256(passcode), stored);
  }

  Future<bool> validateRecoveryCodeForUnlock(String code) async {
    final stored = _user?.appLockRecoveryCode;
    if (stored == null || stored.isEmpty) return false;
    if (stored.startsWith('pbkdf2rc:')) {
      final parts = stored.split(':');
      if (parts.length != 3) return false;
      final derived = await compute(_doPbkdf2, [code, parts[1]]);
      return _timingSafeEquals(derived, parts[2]);
    }
    return _timingSafeEquals(_sha256(code), stored);
  }

  Future<void> disableAppLock() {
    return _queueWork(() async {
      final user = _user;
      final authRepository = _authRepository;
      if (user == null || authRepository == null) return;
      _user = await authRepository.updateProfile(
        user.copyWith(
          appLockPasscodeHash: '',
          appLockRecoveryCode: '',
          lockOnLaunch: false,
          biometricEnabled: false,
        ),
      );
      _lockOnLaunch = false;
      _biometric = false;
      notifyListeners();
    });
  }

  Future<void> setAppLockPasscode(String passcode) {
    final recovery = _generateRecoveryCode();
    final pinSalt = _generateSalt();
    final recoverySalt = _generateSalt();
    return _queueWork(() async {
      final user = _user;
      final authRepository = _authRepository;
      if (user == null || authRepository == null) return;
      final pinHash = await compute(_doPbkdf2, [passcode, pinSalt]);
      final recoveryHash = await compute(_doPbkdf2, [recovery, recoverySalt]);
      _user = await authRepository.updateProfile(
        user.copyWith(
          appLockPasscodeHash: 'pbkdf2:$pinSalt:$pinHash',
          appLockRecoveryCode: 'pbkdf2rc:$recoverySalt:$recoveryHash',
        ),
      );
      _pendingRecoveryCode = recovery;
      notifyListeners();
    });
  }

  static String _sha256(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  static bool _timingSafeEquals(String a, String b) {
    final ab = utf8.encode(a);
    final bb = utf8.encode(b);
    if (ab.length != bb.length) return false;
    var diff = 0;
    for (var i = 0; i < ab.length; i++) {
      diff |= ab[i] ^ bb[i];
    }
    return diff == 0;
  }

  static const int _pbkdf2Iterations = 50000;

  static String _pbkdf2(String password, String saltHex) {
    final keyBytes = utf8.encode(password);
    final saltBytes = Uint8List(saltHex.length ~/ 2);
    for (var i = 0; i < saltBytes.length; i++) {
      saltBytes[i] = int.parse(saltHex.substring(i * 2, i * 2 + 2), radix: 16);
    }

    final hmac = Hmac(sha256, keyBytes);

    final blockInput = Uint8List(saltBytes.length + 4);
    blockInput.setRange(0, saltBytes.length, saltBytes);
    blockInput[saltBytes.length + 3] = 1;

    var u = Uint8List.fromList(hmac.convert(blockInput).bytes);
    final dk = Uint8List.fromList(u);

    for (var i = 1; i < _pbkdf2Iterations; i++) {
      u = Uint8List.fromList(hmac.convert(u).bytes);
      for (var j = 0; j < dk.length; j++) {
        dk[j] ^= u[j];
      }
    }

    assert(dk.length == 32, '_pbkdf2: unexpected dk length ${dk.length}');
    return dk.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static String _generateRecoveryCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(12, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  static String _generateSalt() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Future<void> get ready => _pendingWork;
  bool get isLoaded => _isLoaded;

  void loadFromUser(AppUser user) {
    _user = user;
    var changed = false;

    if (!_hasPersistedMonthlyBudget && user.monthlyIncome > 0) {
      _monthlyBudget = user.monthlyIncome;
      changed = true;
    }
    if (!_hasPersistedCurrency && user.currency.isNotEmpty) {
      _currency = user.currency;
      changed = true;
    }

    if (!changed) return;

    _schedulePersist();
    notifyListeners();
  }

  Future<void> load({required AppUser user}) async {
    await ready;

    _resetAccountScopedValues();
    _user = user;
    _applyUserSettings(user);

    final budgetRepository = _budgetRepository;
    if (budgetRepository != null) {
      final budget = await budgetRepository.fetchByMonth(
        user.id,
        _currentBudgetMonth(),
      );
      if (budget != null) {
        _monthlyBudget = budget.totalLimit;
        _hasPersistedMonthlyBudget = true;
      }
    }

    final notificationRepository = _notificationRepository;
    if (notificationRepository != null) {
      _notificationSetting = await notificationRepository.fetchSetting(user.id);
      if (_notificationSetting != null) {
        _applyNotificationSettings(_notificationSetting!);
      }
    }

    _isLoaded = true;
    _schedulePersist();
    notifyListeners();
  }

  Future<void> updateMonthlyBudget(int value) {
    _monthlyBudget = value;
    _hasPersistedMonthlyBudget = true;
    notifyListeners();
    return _queueWork(() async {
      await _persist();
      final user = _user;
      final budgetRepository = _budgetRepository;
      if (budgetRepository == null || user == null) return;
      await budgetRepository.upsert(
        Budget(
          id: '',
          userId: user.id,
          month: _currentBudgetMonth(),
          totalLimit: value,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    });
  }

  Future<void> updateBudgetWarnings({
    int? primary,
    int? secondary,
    String? startDay,
  }) async {
    if (primary != null) _budgetWarningPrimary = primary;
    if (secondary != null) _budgetWarningSecondary = secondary;
    if (startDay != null) _budgetStartDay = startDay;
    notifyListeners();
    return _queueWork(() async {
      await _persist();
      await _persistUserProfile();
    });
  }

  Future<void> updateAlerts({
    bool? budgetAlert,
    bool? fixedExpenseAlert,
    bool? reminderAlert,
  }) async {
    final prevBudgetAlert = _budgetAlert;
    final prevFixedExpenseAlert = _fixedExpenseAlert;
    final prevReminderAlert = _reminderAlert;

    if (budgetAlert != null) _budgetAlert = budgetAlert;
    if (fixedExpenseAlert != null) _fixedExpenseAlert = fixedExpenseAlert;
    if (reminderAlert != null) _reminderAlert = reminderAlert;
    notifyListeners();
    return _queueWork(() async {
      try {
        await _persist();
        await _persistNotificationSettings();
      } catch (e) {
        _budgetAlert = prevBudgetAlert;
        _fixedExpenseAlert = prevFixedExpenseAlert;
        _reminderAlert = prevReminderAlert;
        notifyListeners();
        rethrow;
      }
    });
  }

  Future<void> updateLocale({String? language, String? currency}) async {
    if (language != null) _language = language;
    if (currency != null) {
      _currency = currency;
      _hasPersistedCurrency = true;
    }
    notifyListeners();
    return _queueWork(() async {
      await _persist();
      await _persistUserProfile();
    });
  }

  Future<void> updatePreferences({
    bool? compactView,
    bool? showWeeklySummary,
    String? themeLabel,
    String? startScreen,
  }) async {
    if (compactView != null) _compactView = compactView;
    if (showWeeklySummary != null) _showWeeklySummary = showWeeklySummary;
    if (themeLabel != null) _themeLabel = themeLabel;
    if (startScreen != null) _startScreen = startScreen;
    notifyListeners();
    return _queueWork(() async {
      await _persist();
      await _persistUserProfile();
    });
  }

  Future<void> updateSecurity({bool? lockOnLaunch, bool? biometric}) async {
    final prevLockOnLaunch = _lockOnLaunch;
    final prevBiometric = _biometric;
    if (lockOnLaunch != null) _lockOnLaunch = lockOnLaunch;
    if (biometric != null) _biometric = biometric;
    notifyListeners();
    return _queueWork(() async {
      try {
        await _persist();
        await _persistUserProfile();
      } catch (e) {
        _lockOnLaunch = prevLockOnLaunch;
        _biometric = prevBiometric;
        notifyListeners();
        rethrow;
      }
    });
  }

  Future<void> _loadFromStorage() async {
    try {
      final raw = await _storage.read(_storageKey);
      if (raw == null || raw.isEmpty) return;

      final map = jsonDecode(raw) as Map<String, dynamic>;
      _hasPersistedMonthlyBudget = map.containsKey('monthlyBudget');
      _hasPersistedCurrency = map.containsKey('currency');

      _monthlyBudget = map['monthlyBudget'] as int? ?? _monthlyBudget;
      _budgetWarningPrimary =
          map['budgetWarningPrimary'] as int? ?? _budgetWarningPrimary;
      _budgetWarningSecondary =
          map['budgetWarningSecondary'] as int? ?? _budgetWarningSecondary;
      _budgetStartDay = map['budgetStartDay'] as String? ?? _budgetStartDay;
      _budgetAlert = map['budgetAlert'] as bool? ?? _budgetAlert;
      _fixedExpenseAlert =
          map['fixedExpenseAlert'] as bool? ?? _fixedExpenseAlert;
      _reminderAlert = map['reminderAlert'] as bool? ?? _reminderAlert;
      _language = map['language'] as String? ?? _language;
      _currency = map['currency'] as String? ?? _currency;
      _compactView = map['compactView'] as bool? ?? _compactView;
      _showWeeklySummary =
          map['showWeeklySummary'] as bool? ?? _showWeeklySummary;
      _themeLabel = map['themeLabel'] as String? ?? _themeLabel;
      _startScreen = map['startScreen'] as String? ?? _startScreen;
      _lockOnLaunch = map['lockOnLaunch'] as bool? ?? _lockOnLaunch;
      _biometric = map['biometric'] as bool? ?? _biometric;
      notifyListeners();
    } catch (e) {
      debugPrint('[SettingsProvider] Storage read failed: $e');
    }
  }

  void _schedulePersist() {
    _pendingWork = _pendingWork.then((_) => _persist());
  }

  Future<void> _persist() async {
    try {
      await _storage.write(
        _storageKey,
        jsonEncode(<String, dynamic>{
          'monthlyBudget': _monthlyBudget,
          'budgetWarningPrimary': _budgetWarningPrimary,
          'budgetWarningSecondary': _budgetWarningSecondary,
          'budgetStartDay': _budgetStartDay,
          'budgetAlert': _budgetAlert,
          'fixedExpenseAlert': _fixedExpenseAlert,
          'reminderAlert': _reminderAlert,
          'language': _language,
          'currency': _currency,
          'compactView': _compactView,
          'showWeeklySummary': _showWeeklySummary,
          'themeLabel': _themeLabel,
          'startScreen': _startScreen,
          'lockOnLaunch': _lockOnLaunch,
          'biometric': _biometric,
        }),
      );
    } catch (_) {}
  }

  Future<void> _queueWork(Future<void> Function() action) {
    final future = _pendingWork.then((_) => action());
    _pendingWork = future.catchError((Object e) {
      debugPrint('[SettingsProvider] queued work failed: $e');
    });
    return future;
  }

  void resetForSignedOut() {
    _resetAccountScopedValues();
    _user = null;
    _notificationSetting = null;
    notifyListeners();
  }

  void _applyUserSettings(AppUser user) {
    if (user.monthlyIncome > 0) {
      _monthlyBudget = user.monthlyIncome;
    }
    _currency = user.currency;
    _language = user.language;
    _themeLabel = user.themeLabel;
    _startScreen = user.startScreen;
    _compactView = user.compactView;
    _showWeeklySummary = user.showWeeklySummary;
    _lockOnLaunch = user.lockOnLaunch;
    _biometric = user.biometricEnabled;
    _budgetWarningPrimary = user.budgetWarningPrimary;
    _budgetWarningSecondary = user.budgetWarningSecondary;
    _budgetStartDay = user.budgetStartDay;
  }

  void _applyNotificationSettings(NotificationSetting setting) {
    _budgetAlert = setting.budgetAlertEnabled;
    _fixedExpenseAlert = setting.fixedExpenseAlertEnabled;
    _reminderAlert = setting.dailySummaryEnabled;
  }

  void _resetAccountScopedValues() {
    _monthlyBudget = 2000000;
    _budgetWarningPrimary = 80;
    _budgetWarningSecondary = 100;
    _budgetStartDay = '매월 1일';
    _budgetAlert = true;
    _fixedExpenseAlert = true;
    _reminderAlert = false;
    _language = '한국어';
    _currency = 'KRW';
    _compactView = false;
    _showWeeklySummary = true;
    _themeLabel = '라이트';
    _startScreen = '홈';
    _lockOnLaunch = false;
    _biometric = false;
    _hasPersistedMonthlyBudget = false;
    _hasPersistedCurrency = false;
  }

  Future<void> _persistUserProfile() async {
    final user = _user;
    final authRepository = _authRepository;
    if (user == null || authRepository == null) return;

    _user = await authRepository.updateProfileFields(
      user.copyWith(
        currency: _currency,
        language: _language,
        themeLabel: _themeLabel,
        startScreen: _startScreen,
        compactView: _compactView,
        showWeeklySummary: _showWeeklySummary,
        lockOnLaunch: _lockOnLaunch,
        biometricEnabled: _biometric,
        budgetWarningPrimary: _budgetWarningPrimary,
        budgetWarningSecondary: _budgetWarningSecondary,
        budgetStartDay: _budgetStartDay,
      ),
    );
  }

  Future<void> _persistNotificationSettings() async {
    final notificationRepository = _notificationRepository;
    final user = _user;
    if (notificationRepository == null || user == null) return;

    final masterEnabled = _budgetAlert || _fixedExpenseAlert || _reminderAlert;
    final base =
        _notificationSetting ??
        NotificationSetting(
          id: '',
          userId: user.id,
          masterEnabled: masterEnabled,
          budgetAlertEnabled: _budgetAlert,
          fixedExpenseAlertEnabled: _fixedExpenseAlert,
          dailySummaryEnabled: _reminderAlert,
          dailySummaryTime: '20:00',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

    _notificationSetting = await notificationRepository.updateSetting(
      base.copyWith(
        masterEnabled: masterEnabled,
        budgetAlertEnabled: _budgetAlert,
        fixedExpenseAlertEnabled: _fixedExpenseAlert,
        dailySummaryEnabled: _reminderAlert,
      ),
    );
  }

  String _currentBudgetMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }
}
