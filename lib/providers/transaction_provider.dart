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

  // Cache is keyed by '$userId:YYYY-MM' to prevent cross-user data leaks.
  final Map<String, List<AppTransaction>> _transactionsByMonth = {};
  final Map<String, AppTransaction> _transactionById = {};
  bool _isLoading = false;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  List<MonthlyTrend> _monthlyTrends = [];
  String? _currentUserId;
  int _monthlyTrendCount = 5;

  /// Incremented by [clear]; in-flight futures compare against their captured
  /// value to abort stale writes after a sign-out / user-switch.
  int _generation = 0;

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

    final capturedGeneration = _generation;
    try {
      final scopedKey = _scopedKey(userId, normalizedMonth);
      final fetched = await _repo.fetchByMonth(userId, _monthKey(normalizedMonth));
      // Abort if clear() was called while the fetch was in-flight.
      if (_generation != capturedGeneration) return;
      _transactionsByMonth[scopedKey] = fetched;
      for (final tx in fetched) {
        _transactionById[tx.id] = tx;
      }
    } finally {
      if (_generation == capturedGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Loads monthly trends for [count] recent months.
  ///
  /// Set [forceRefresh] to true to bypass the in-memory cache and re-fetch
  /// each month's data from the repository (e.g. for pull-to-refresh).
  Future<void> loadMonthlyTrends(
    String userId, {
    int count = 5,
    bool forceRefresh = false,
  }) async {
    if (userId.trim().isEmpty) return;

    _currentUserId = userId;
    _monthlyTrendCount = count;

    if (forceRefresh) {
      _evictMonthlyTrendCache(userId, count);
    }

    final capturedGeneration = _generation;
    final trends = await _buildMonthlyTrends(userId, count: count);
    if (_generation != capturedGeneration) return;
    _monthlyTrends = trends;
    notifyListeners();
  }

  /// Removes cached months covered by the trend window so the next
  /// [_buildMonthlyTrends] call fetches fresh data from the server.
  void _evictMonthlyTrendCache(String userId, int count) {
    final now = DateTime.now();
    for (var i = 0; i < count; i++) {
      final monthOffset = count - 1 - i;
      final dt = DateTime(now.year, now.month - monthOffset);
      _transactionsByMonth.remove(_scopedKey(userId, dt));
    }
  }

  Future<List<MonthlyTrend>> _buildMonthlyTrends(
    String userId, {
    required int count,
  }) async {
    final capturedGeneration = _generation;
    final now = DateTime.now();
    final futures = List<Future<MonthlyTrend>>.generate(count, (i) {
      final monthOffset = count - 1 - i;
      final dt = DateTime(now.year, now.month - monthOffset);
      final scopedKey = _scopedKey(userId, dt);
      final plainKey = _monthKey(dt);

      if (_transactionsByMonth.containsKey(scopedKey)) {
        final txs = _transactionsByMonth[scopedKey]!;
        final income =
            txs.where((t) => t.isIncome).fold(0, (sum, t) => sum + t.amount);
        final expense =
            txs.where((t) => t.isExpense).fold(0, (sum, t) => sum + t.amount);
        return Future.value(MonthlyTrend(month: dt, income: income, expense: expense));
      }

      return _repo.fetchByMonth(userId, plainKey).then((txs) {
        // Discard result if clear() was called while the fetch was in-flight.
        if (_generation != capturedGeneration) {
          return MonthlyTrend(month: dt, income: 0, expense: 0);
        }
        _transactionsByMonth[scopedKey] = txs;
        for (final tx in txs) {
          _transactionById[tx.id] = tx;
        }
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
    final capturedGeneration = _generation;
    final trends = await _buildMonthlyTrends(
      userId,
      count: _monthlyTrendCount,
    );
    if (_generation != capturedGeneration) return;
    _monthlyTrends = trends;
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
      _removeFromMonthCache(existing.id, existing.occurredAt, existing.userId);
    }
    _upsertIntoMonthCache(updated);
    await _refreshMonthlyTrends(updated.userId);
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    final existing = _findById(id);
    await _repo.delete(id);
    if (existing != null) {
      _removeFromMonthCache(id, existing.occurredAt, existing.userId);
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
    final userId = _currentUserId;
    if (userId == null) return const [];
    return List.unmodifiable(
      _transactionsByMonth[_scopedKey(userId, month)] ?? const <AppTransaction>[],
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

  /// Clears all cached data and increments the generation counter so that any
  /// in-flight fetch callbacks recognise they are stale and do not write.
  void clear() {
    _generation++;
    _transactionsByMonth.clear();
    _transactionById.clear();
    _monthlyTrends = [];
    _isLoading = false;
    _currentUserId = null;
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
    notifyListeners();
  }

  String _monthKey(DateTime month) =>
      '${month.year}-${month.month.toString().padLeft(2, '0')}';

  /// Returns a cache key scoped to [userId] so data from different users
  /// never collides in the same map.
  String _scopedKey(String userId, DateTime month) =>
      '$userId:${_monthKey(month)}';

  void _ensureUserId(String userId) {
    if (userId.trim().isEmpty) {
      throw StateError('A signed-in user is required to modify transactions.');
    }
  }

  AppTransaction? _findById(String id) => _transactionById[id];

  void _upsertIntoMonthCache(AppTransaction transaction) {
    final key = _scopedKey(transaction.userId, transaction.occurredAt);
    final items = List<AppTransaction>.from(
      _transactionsByMonth[key] ?? const <AppTransaction>[],
    )..removeWhere((existing) => existing.id == transaction.id);
    items.add(transaction);
    items.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    _transactionsByMonth[key] = items;
    _transactionById[transaction.id] = transaction;
  }

  void _removeFromMonthCache(String id, DateTime month, String userId) {
    final key = _scopedKey(userId, month);
    final items = _transactionsByMonth[key];
    if (items == null) return;
    items.removeWhere((transaction) => transaction.id == id);
    _transactionById.remove(id);
    if (items.isEmpty) {
      _transactionsByMonth.remove(key);
      return;
    }
    _transactionsByMonth[key] = List<AppTransaction>.from(items)
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  }
}
