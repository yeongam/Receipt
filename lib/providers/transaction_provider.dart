import 'package:flutter/foundation.dart';
import '../data/models/transaction.dart';
import '../data/repositories/transaction_repository.dart';

class CategorySummary {
  final String categoryId;
  final String categoryName;
  final int amount;

  const CategorySummary({
    required this.categoryId,
    required this.categoryName,
    required this.amount,
  });
}

class MonthlyTrend {
  final DateTime month;
  final int income;
  final int expense;

  const MonthlyTrend({
    required this.month,
    required this.income,
    required this.expense,
  });
}

class TransactionProvider extends ChangeNotifier {
  final TransactionRepository _repo;

  final Map<String, List<AppTransaction>> _transactionsByMonth = {};
  bool _isLoading = false;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  List<MonthlyTrend> _monthlyTrends = [];
  String? _currentUserId;
  int _monthlyTrendCount = 5;

  TransactionProvider(this._repo);

  List<AppTransaction> get transactions =>
      List.unmodifiable(transactionsForMonth(_selectedMonth));
  bool get isLoading => _isLoading;
  DateTime get selectedMonth => _selectedMonth;
  List<MonthlyTrend> get monthlyTrends => List.unmodifiable(_monthlyTrends);

  Future<void> loadMonth(
    String userId,
    DateTime month, {
    bool select = true,
  }) async {
    if (userId.trim().isEmpty) return;

    _currentUserId = userId;
    final normalizedMonth = DateTime(month.year, month.month);
    if (select) {
      _selectedMonth = normalizedMonth;
    }
    _isLoading = true;
    notifyListeners();
    try {
      final key = _monthKey(normalizedMonth);
      _transactionsByMonth[key] = await _repo.fetchByMonth(userId, key);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMonthlyTrends(String userId, {int count = 5}) async {
    if (userId.trim().isEmpty) return;

    _currentUserId = userId;
    _monthlyTrendCount = count;
    _monthlyTrends = await _buildMonthlyTrends(userId, count: count);
    notifyListeners();
  }

  Future<List<MonthlyTrend>> _buildMonthlyTrends(
    String userId, {
    required int count,
  }) async {
    final now = DateTime.now();
    final futures = List.generate(count, (i) {
      final monthOffset = count - 1 - i;
      final year = now.year + ((now.month - monthOffset - 1) ~/ 12);
      final month = ((now.month - monthOffset - 1) % 12 + 12) % 12 + 1;
      final dt = DateTime(year, month);
      final key = '$year-${month.toString().padLeft(2, '0')}';
      return _repo.fetchByMonth(userId, key).then((txs) {
        final income =
            txs.where((t) => t.isIncome).fold(0, (sum, t) => sum + t.amount);
        final expense =
            txs.where((t) => t.isExpense).fold(0, (sum, t) => sum + t.amount);
        return MonthlyTrend(month: dt, income: income, expense: expense);
      });
    });
    return Future.wait(futures);
  }

  Future<void> _refreshMonthlyTrends(String? userId) async {
    if (userId == null || userId.isEmpty || _monthlyTrends.isEmpty) return;
    _monthlyTrends = await _buildMonthlyTrends(
      userId,
      count: _monthlyTrendCount,
    );
  }

  Future<void> addTransaction(AppTransaction tx) async {
    _ensureUserId(tx.userId);
    final created = await _repo.insert(tx);
    _upsertIntoMonthCache(created);
    await _refreshMonthlyTrends(created.userId);
    notifyListeners();
  }

  Future<void> updateTransaction(AppTransaction tx) async {
    _ensureUserId(tx.userId);
    final existing = _findById(tx.id);
    final updated = await _repo.update(tx);
    if (existing != null) {
      _removeFromMonthCache(existing.id, existing.occurredAt);
    }
    _upsertIntoMonthCache(updated);
    await _refreshMonthlyTrends(updated.userId);
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    final existing = _findById(id);
    await _repo.delete(id);
    if (existing != null) {
      _removeFromMonthCache(id, existing.occurredAt);
    }
    await _refreshMonthlyTrends(existing?.userId ?? _currentUserId);
    notifyListeners();
  }

  List<AppTransaction> recentTransactions({
    int limit = 5,
    DateTime? month,
  }) {
    return transactionsForMonth(month ?? _selectedMonth).take(limit).toList();
  }

  List<AppTransaction> transactionsForMonth(DateTime month) {
    return List.unmodifiable(
      _transactionsByMonth[_monthKey(month)] ?? const <AppTransaction>[],
    );
  }

  int totalIncomeForMonth(DateTime month) {
    return transactionsForMonth(month)
        .where((t) => t.isIncome)
        .fold(0, (sum, t) => sum + t.amount);
  }

  int totalExpenseForMonth(DateTime month) {
    return transactionsForMonth(month)
        .where((t) => t.isExpense)
        .fold(0, (sum, t) => sum + t.amount);
  }

  int balanceForMonth(DateTime month) {
    return totalIncomeForMonth(month) - totalExpenseForMonth(month);
  }

  List<CategorySummary> expenseCategoriesForMonth(
    DateTime month,
    Map<String, String> categoryNames,
  ) {
    final Map<String, int> totals = {};
    for (final t in transactionsForMonth(month)) {
      if (!t.isExpense || t.categoryId == null) continue;
      totals.update(
        t.categoryId!,
        (v) => v + t.amount,
        ifAbsent: () => t.amount,
      );
    }
    return totals.entries
        .map((e) => CategorySummary(
              categoryId: e.key,
              categoryName: categoryNames[e.key] ?? '기타',
              amount: e.value,
            ))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }

  void clear() {
    _transactionsByMonth.clear();
    _monthlyTrends = [];
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
    notifyListeners();
  }

  String _monthKey(DateTime month) =>
      '${month.year}-${month.month.toString().padLeft(2, '0')}';

  void _ensureUserId(String userId) {
    if (userId.trim().isEmpty) {
      throw StateError('A signed-in user is required to modify transactions.');
    }
  }

  AppTransaction? _findById(String id) {
    for (final items in _transactionsByMonth.values) {
      final match =
          items.where((transaction) => transaction.id == id).firstOrNull;
      if (match != null) {
        return match;
      }
    }
    return null;
  }

  void _upsertIntoMonthCache(AppTransaction transaction) {
    final key = _monthKey(transaction.occurredAt);
    final items = List<AppTransaction>.from(
      _transactionsByMonth[key] ?? const <AppTransaction>[],
    )..removeWhere((existing) => existing.id == transaction.id);
    items.add(transaction);
    items.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    _transactionsByMonth[key] = items;
  }

  void _removeFromMonthCache(String id, DateTime month) {
    final key = _monthKey(month);
    final items = _transactionsByMonth[key];
    if (items == null) return;
    items.removeWhere((transaction) => transaction.id == id);
    if (items.isEmpty) {
      _transactionsByMonth.remove(key);
      return;
    }
    _transactionsByMonth[key] = List<AppTransaction>.from(items)
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  }
}
