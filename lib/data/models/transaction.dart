enum TransactionType { income, expense }

class AppTransaction {
  final String id;
  final String userId;
  final String? categoryId;
  final String? fixedExpenseId;
  final TransactionType type;
  final int amount;
  final String title;
  final String? memo;
  final DateTime occurredAt;
  final DateTime createdAt;

  const AppTransaction({
    required this.id,
    required this.userId,
    this.categoryId,
    this.fixedExpenseId,
    required this.type,
    required this.amount,
    required this.title,
    this.memo,
    required this.occurredAt,
    required this.createdAt,
  });

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;

  factory AppTransaction.fromMap(Map<String, dynamic> map) {
    return AppTransaction(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      categoryId: map['category_id'] as String?,
      fixedExpenseId: map['fixed_expense_id'] as String?,
      type: map['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      amount: map['amount'] as int,
      title: map['title'] as String,
      memo: map['memo'] as String?,
      occurredAt: DateTime.parse(map['occurred_at'] as String).toLocal(),
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId,
      if (categoryId != null) 'category_id': categoryId,
      if (fixedExpenseId != null) 'fixed_expense_id': fixedExpenseId,
      'type': type == TransactionType.income ? 'income' : 'expense',
      'amount': amount,
      'title': title,
      if (memo != null) 'memo': memo,
      'occurred_at': occurredAt.toUtc().toIso8601String(),
    };
  }
}
