class NotificationSetting {
  final String id;
  final String userId;
  final bool masterEnabled;
  final bool budgetAlertEnabled;
  final bool fixedExpenseAlertEnabled;
  final bool dailySummaryEnabled;
  final String dailySummaryTime; // 'HH:mm'
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotificationSetting({
    required this.id,
    required this.userId,
    required this.masterEnabled,
    this.budgetAlertEnabled = true,
    this.fixedExpenseAlertEnabled = true,
    required this.dailySummaryEnabled,
    required this.dailySummaryTime,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationSetting.fromMap(Map<String, dynamic> map) {
    return NotificationSetting(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      masterEnabled: map['master_enabled'] as bool? ?? true,
      budgetAlertEnabled: map['budget_alert_enabled'] as bool? ?? true,
      fixedExpenseAlertEnabled:
          map['fixed_expense_alert_enabled'] as bool? ?? true,
      dailySummaryEnabled: map['daily_summary_enabled'] as bool? ?? false,
      dailySummaryTime: map['daily_summary_time'] as String? ?? '20:00',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'master_enabled': masterEnabled,
      'budget_alert_enabled': budgetAlertEnabled,
      'fixed_expense_alert_enabled': fixedExpenseAlertEnabled,
      'daily_summary_enabled': dailySummaryEnabled,
      'daily_summary_time': dailySummaryTime,
    };
  }

  NotificationSetting copyWith({
    bool? masterEnabled,
    bool? budgetAlertEnabled,
    bool? fixedExpenseAlertEnabled,
    bool? dailySummaryEnabled,
    String? dailySummaryTime,
  }) {
    return NotificationSetting(
      id: id,
      userId: userId,
      masterEnabled: masterEnabled ?? this.masterEnabled,
      budgetAlertEnabled: budgetAlertEnabled ?? this.budgetAlertEnabled,
      fixedExpenseAlertEnabled:
          fixedExpenseAlertEnabled ?? this.fixedExpenseAlertEnabled,
      dailySummaryEnabled: dailySummaryEnabled ?? this.dailySummaryEnabled,
      dailySummaryTime: dailySummaryTime ?? this.dailySummaryTime,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
