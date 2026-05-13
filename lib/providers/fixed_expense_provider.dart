import 'package:flutter/foundation.dart';
import '../data/models/fixed_expense.dart';
import '../data/repositories/fixed_expense_repository.dart';

class FixedExpenseProvider extends ChangeNotifier {
  final FixedExpenseRepository _repo;

  List<FixedExpense> _items = [];
  bool _isLoading = false;

  FixedExpenseProvider(this._repo);

  List<FixedExpense> get items => List.unmodifiable(_items);
  List<FixedExpense> get activeItems =>
      List.unmodifiable(_items.where((e) => e.isActive));
  bool get isLoading => _isLoading;

  Future<void> load(String userId) async {
    if (userId.trim().isEmpty) {
      return;
    }

    _isLoading = true;
    notifyListeners();
    try {
      _items = await _repo.fetchAll(userId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<FixedExpense> add(FixedExpense fe) async {
    _ensureUserId(fe.userId);
    final created = await _repo.insert(fe);
    _items.add(created);
    notifyListeners();
    return created;
  }

  Future<void> edit(FixedExpense fe) async {
    _ensureUserId(fe.userId);
    final updated = await _repo.update(fe);
    final idx = _items.indexWhere((e) => e.id == fe.id);
    if (idx != -1) _items[idx] = updated;
    notifyListeners();
  }

  Future<void> remove(String id) async {
    await _repo.delete(id);
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void clear() {
    _items = [];
    notifyListeners();
  }

  void _ensureUserId(String userId) {
    if (userId.trim().isEmpty) {
      throw StateError(
        'A signed-in user is required to modify fixed expenses.',
      );
    }
  }
}
