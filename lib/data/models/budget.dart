class Budget {
  final String id;
  final String userId;
  final String month; // 'YYYY-MM'
  final int totalLimit;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Budget({
    required this.id,
    required this.userId,
    required this.month,
    required this.totalLimit,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      month: map['month'] as String,
      totalLimit: map['total_limit'] as int,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId,
      'month': month,
      'total_limit': totalLimit,
      if (note != null) 'note': note,
    };
  }
}

class BudgetCategory {
  final String id;
  final String userId;
  final String month;
  final String categoryId;
  final int limitAmount;
  final int spentAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BudgetCategory({
    required this.id,
    required this.userId,
    required this.month,
    required this.categoryId,
    required this.limitAmount,
    required this.spentAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BudgetCategory.fromMap(Map<String, dynamic> map) {
    return BudgetCategory(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      month: map['month'] as String,
      categoryId: map['category_id'] as String,
      limitAmount: map['limit_amount'] as int,
      spentAmount: map['spent_amount'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId,
      'month': month,
      'category_id': categoryId,
      'limit_amount': limitAmount,
      'spent_amount': spentAmount,
    };
  }
}
