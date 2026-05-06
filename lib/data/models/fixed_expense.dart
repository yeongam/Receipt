class FixedExpense {
  final String id;
  final String userId;
  final String? categoryId;
  final String title;
  final int amount;
  final String cycle; // 'monthly' | 'yearly'
  final int billingDay;
  final String? nextDueDate;
  final String? memo;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FixedExpense({
    required this.id,
    required this.userId,
    this.categoryId,
    required this.title,
    required this.amount,
    required this.cycle,
    required this.billingDay,
    this.nextDueDate,
    this.memo,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isMonthly => cycle == 'monthly';
  bool get isYearly => cycle == 'yearly';

  factory FixedExpense.fromMap(Map<String, dynamic> map) {
    return FixedExpense(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      categoryId: map['category_id'] as String?,
      title: map['title'] as String,
      amount: map['amount'] as int,
      cycle: map['cycle'] as String,
      billingDay: map['billing_day'] as int,
      nextDueDate: map['next_due_date'] as String?,
      memo: map['memo'] as String?,
      isActive: map['is_active'] as bool,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId,
      if (categoryId != null) 'category_id': categoryId,
      'title': title,
      'amount': amount,
      'cycle': cycle,
      'billing_day': billingDay,
      if (nextDueDate != null) 'next_due_date': nextDueDate,
      if (memo != null) 'memo': memo,
      'is_active': isActive,
    };
  }
}
