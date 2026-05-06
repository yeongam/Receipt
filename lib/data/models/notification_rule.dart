class NotificationRule {
  final String id;
  final String userId;
  final String fixedExpenseId;
  final String title;
  final bool isEnabled;
  final int remindDaysBefore;
  final String remindAt; // 'HH:mm'
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotificationRule({
    required this.id,
    required this.userId,
    required this.fixedExpenseId,
    required this.title,
    required this.isEnabled,
    required this.remindDaysBefore,
    required this.remindAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationRule.fromMap(Map<String, dynamic> map) {
    return NotificationRule(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      fixedExpenseId: map['fixed_expense_id'] as String,
      title: map['title'] as String,
      isEnabled: map['is_enabled'] as bool,
      remindDaysBefore: map['remind_days_before'] as int,
      remindAt: map['remind_at'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId,
      'fixed_expense_id': fixedExpenseId,
      'title': title,
      'is_enabled': isEnabled,
      'remind_days_before': remindDaysBefore,
      'remind_at': remindAt,
    };
  }
}
