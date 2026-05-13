// Sentinel for "not provided" in copyWith — allows explicitly passing null.
const _notSet = Object();

class AppUser {
  final String id;
  final String username;
  final String name;
  final int monthlyIncome;
  final String currency;
  final String language;
  final String themeLabel;
  final String startScreen;
  final bool compactView;
  final bool showWeeklySummary;
  final bool lockOnLaunch;
  final bool biometricEnabled;
  final int budgetWarningPrimary;
  final int budgetWarningSecondary;
  final String budgetStartDay;
  final bool isProfileCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? appLockPasscodeHash;
  final String? appLockRecoveryCode;

  const AppUser({
    required this.id,
    required this.username,
    required this.name,
    required this.monthlyIncome,
    required this.currency,
    this.language = '한국어',
    this.themeLabel = '라이트',
    this.startScreen = '홈',
    this.compactView = false,
    this.showWeeklySummary = true,
    this.lockOnLaunch = false,
    this.biometricEnabled = false,
    this.budgetWarningPrimary = 80,
    this.budgetWarningSecondary = 100,
    this.budgetStartDay = '매월 1일',
    required this.isProfileCompleted,
    required this.createdAt,
    required this.updatedAt,
    this.appLockPasscodeHash,
    this.appLockRecoveryCode,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String? ??
          (throw const FormatException('AppUser.fromMap: missing id')),
      username: map['username'] as String? ??
          (throw const FormatException('AppUser.fromMap: missing username')),
      name: map['name'] as String? ?? '',
      monthlyIncome: (map['monthly_income'] as num?)?.toInt() ?? 0,
      currency: map['currency'] as String? ?? 'KRW',
      language: map['language'] as String? ?? '한국어',
      themeLabel: map['theme_label'] as String? ?? '라이트',
      startScreen: map['start_screen'] as String? ?? '홈',
      compactView: map['compact_view'] as bool? ?? false,
      showWeeklySummary: map['show_weekly_summary'] as bool? ?? true,
      lockOnLaunch: map['lock_on_launch'] as bool? ?? false,
      biometricEnabled: map['biometric_enabled'] as bool? ?? false,
      budgetWarningPrimary:
          (map['budget_warning_primary'] as num?)?.toInt() ?? 80,
      budgetWarningSecondary:
          (map['budget_warning_secondary'] as num?)?.toInt() ?? 100,
      budgetStartDay: map['budget_start_day'] as String? ?? '매월 1일',
      isProfileCompleted: map['is_profile_completed'] as bool? ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
      appLockPasscodeHash: map['app_lock_passcode_hash'] as String?,
      appLockRecoveryCode: map['app_lock_recovery_code'] as String?,
    );
  }

  /// Full update map including security fields.
  /// Use only when explicitly writing app-lock data (setAppLockPasscode, disableAppLock).
  Map<String, dynamic> toUpdateMap() {
    return {
      ...toProfileUpdateMap(),
      'app_lock_passcode_hash': appLockPasscodeHash,
      'app_lock_recovery_code': appLockRecoveryCode,
    };
  }

  /// Profile-only update map — excludes app_lock security fields.
  /// Use for all routine settings saves to avoid clobbering security data.
  Map<String, dynamic> toProfileUpdateMap() {
    return {
      'name': name,
      'monthly_income': monthlyIncome,
      'currency': currency,
      'language': language,
      'theme_label': themeLabel,
      'start_screen': startScreen,
      'compact_view': compactView,
      'show_weekly_summary': showWeeklySummary,
      'lock_on_launch': lockOnLaunch,
      'biometric_enabled': biometricEnabled,
      'budget_warning_primary': budgetWarningPrimary,
      'budget_warning_secondary': budgetWarningSecondary,
      'budget_start_day': budgetStartDay,
      'is_profile_completed': isProfileCompleted,
    };
  }

  AppUser copyWith({
    String? name,
    int? monthlyIncome,
    String? currency,
    String? language,
    String? themeLabel,
    String? startScreen,
    bool? compactView,
    bool? showWeeklySummary,
    bool? lockOnLaunch,
    bool? biometricEnabled,
    int? budgetWarningPrimary,
    int? budgetWarningSecondary,
    String? budgetStartDay,
    bool? isProfileCompleted,
    // Use sentinel so callers can pass null to explicitly clear these fields.
    Object? appLockPasscodeHash = _notSet,
    Object? appLockRecoveryCode = _notSet,
  }) {
    return AppUser(
      id: id,
      username: username,
      name: name ?? this.name,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      currency: currency ?? this.currency,
      language: language ?? this.language,
      themeLabel: themeLabel ?? this.themeLabel,
      startScreen: startScreen ?? this.startScreen,
      compactView: compactView ?? this.compactView,
      showWeeklySummary: showWeeklySummary ?? this.showWeeklySummary,
      lockOnLaunch: lockOnLaunch ?? this.lockOnLaunch,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      budgetWarningPrimary: budgetWarningPrimary ?? this.budgetWarningPrimary,
      budgetWarningSecondary:
          budgetWarningSecondary ?? this.budgetWarningSecondary,
      budgetStartDay: budgetStartDay ?? this.budgetStartDay,
      isProfileCompleted: isProfileCompleted ?? this.isProfileCompleted,
      createdAt: createdAt,
      updatedAt: updatedAt,
      appLockPasscodeHash: appLockPasscodeHash == _notSet
          ? this.appLockPasscodeHash
          : appLockPasscodeHash as String?,
      appLockRecoveryCode: appLockRecoveryCode == _notSet
          ? this.appLockRecoveryCode
          : appLockRecoveryCode as String?,
    );
  }
}
