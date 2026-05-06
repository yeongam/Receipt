import 'package:flutter/foundation.dart';
import '../data/models/category.dart';
import '../data/repositories/category_repository.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryRepository _repo;

  List<AppCategory> _categories = [];
  bool _isLoading = false;

  CategoryProvider(this._repo);

  List<AppCategory> get categories => List.unmodifiable(_categories);
  List<AppCategory> get incomeCategories =>
      List.unmodifiable(_categories.where((c) => c.isIncome));
  List<AppCategory> get expenseCategories =>
      List.unmodifiable(_categories.where((c) => c.isExpense));
  bool get isLoading => _isLoading;

  Future<void> load(String userId) async {
    if (userId.trim().isEmpty) {
      return;
    }

    _isLoading = true;
    notifyListeners();
    try {
      _categories = await _repo.fetchAll(userId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCategory(AppCategory category) async {
    _ensureUserId(category.userId);
    final created = await _repo.insert(category);
    _categories.add(created);
    notifyListeners();
  }

  Future<void> deleteCategory(String id) async {
    await _repo.delete(id);
    _categories.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  void clear() {
    _categories = [];
    notifyListeners();
  }

  void _ensureUserId(String userId) {
    if (userId.trim().isEmpty) {
      throw StateError('A signed-in user is required to modify categories.');
    }
  }
}
