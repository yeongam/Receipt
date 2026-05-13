import 'package:flutter/foundation.dart';

import '../data/models/notification_rule.dart';
import '../data/repositories/notification_repository.dart';

class NotificationRuleProvider extends ChangeNotifier {
  final NotificationRepository _repo;

  List<NotificationRule> _rules = [];
  bool _isLoading = false;

  NotificationRuleProvider(this._repo);

  List<NotificationRule> get rules => List.unmodifiable(_rules);
  bool get isLoading => _isLoading;

  /// Returns the notification rule for the given fixed expense, or null if none.
  NotificationRule? ruleFor(String fixedExpenseId) =>
      _rules.where((r) => r.fixedExpenseId == fixedExpenseId).firstOrNull;

  Future<void> load(String userId) async {
    if (userId.trim().isEmpty) return;
    _isLoading = true;
    notifyListeners();
    try {
      _rules = await _repo.fetchRules(userId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates a notification rule for a newly added fixed expense.
  /// Defaults: remind 1 day before at 09:00, enabled.
  Future<void> createForExpense({
    required String userId,
    required String fixedExpenseId,
    required String title,
  }) async {
    final draft = NotificationRule(
      id: '',
      userId: userId,
      fixedExpenseId: fixedExpenseId,
      title: title,
      isEnabled: true,
      remindDaysBefore: 1,
      remindAt: '09:00',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final created = await _repo.insertRule(draft);
    _rules.add(created);
    notifyListeners();
  }

  /// Syncs is_enabled for the rule matching [fixedExpenseId].
  /// No-ops silently if no rule exists yet.
  Future<void> setEnabled(String fixedExpenseId, bool enabled) async {
    final rule = ruleFor(fixedExpenseId);
    if (rule == null) return;
    final updated = await _repo.updateRule(rule.copyWith(isEnabled: enabled));
    final idx = _rules.indexWhere((r) => r.id == rule.id);
    if (idx != -1) _rules[idx] = updated;
    notifyListeners();
  }

  /// Removes the in-memory rule for [fixedExpenseId].
  /// The DB row is cascade-deleted by the fixed_expenses foreign key.
  void removeForExpense(String fixedExpenseId) {
    _rules.removeWhere((r) => r.fixedExpenseId == fixedExpenseId);
    notifyListeners();
  }

  void clear() {
    _rules = [];
    notifyListeners();
  }
}
