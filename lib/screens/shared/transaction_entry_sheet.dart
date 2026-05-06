import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/auth/signed_in_user_id.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_preferences_format.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction.dart';
import '../../providers/category_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/transaction_provider.dart';

Future<void> openTransactionEntrySheet(
  BuildContext context,
  TransactionType type,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _TransactionEntrySheet(type: type, hostContext: context),
  );
}

Future<void> openQuickAddHub(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _QuickAddHubSheet(),
  );
}

AppTransaction createTransactionDraft({
  required String userId,
  required TransactionType type,
  required String title,
  required int amount,
  required AppCategory category,
  DateTime? now,
}) {
  final timestamp = now ?? DateTime.now();
  return AppTransaction(
    id: '',
    userId: userId,
    categoryId: category.id,
    type: type,
    amount: amount,
    title: title.trim(),
    occurredAt: timestamp,
    createdAt: timestamp,
  );
}

void _showSaveError(BuildContext context, String message) {
  ScaffoldMessenger.maybeOf(
    context,
  )?.showSnackBar(SnackBar(content: Text(message)));
}

class _QuickAddHubSheet extends StatelessWidget {
  const _QuickAddHubSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              context.tr('입출금 관리', 'Income & expense'),
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.tr(
                '어느 화면에서든 바로 입금이나 출금 내역을 추가할 수 있어요.',
                'Add income or expense entries right away from any screen.',
              ),
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.68),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _QuickAddActionCard(
                    icon: Icons.south_west_rounded,
                    label: context.tr('입금 추가', 'Add income'),
                    helper: context.tr('수입 등록', 'Income'),
                    color: AppColors.accent,
                    backgroundColor: AppColors.accentLight,
                    onTap: () {
                      Navigator.of(context).pop();
                      openTransactionEntrySheet(
                        context,
                        TransactionType.income,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAddActionCard(
                    icon: Icons.north_east_rounded,
                    label: context.tr('출금 추가', 'Add expense'),
                    helper: context.tr('지출 등록', 'Expense'),
                    color: AppColors.expense,
                    backgroundColor: AppColors.expenseLight,
                    onTap: () {
                      Navigator.of(context).pop();
                      openTransactionEntrySheet(
                        context,
                        TransactionType.expense,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAddActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String helper;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _QuickAddActionCard({
    required this.icon,
    required this.label,
    required this.helper,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).inputDecorationTheme.fillColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 14),
            Text(
              label,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              helper,
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.68),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionEntrySheet extends StatefulWidget {
  final TransactionType type;
  final BuildContext hostContext;

  const _TransactionEntrySheet({required this.type, required this.hostContext});

  @override
  State<_TransactionEntrySheet> createState() => _TransactionEntrySheetState();
}

class _TransactionEntrySheetState extends State<_TransactionEntrySheet> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String? _selectedCategoryId;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.type == TransactionType.income;
    final colorScheme = Theme.of(context).colorScheme;
    final categoryProvider = context.watch<CategoryProvider>();
    final availableCategories = isIncome
        ? categoryProvider.incomeCategories
        : categoryProvider.expenseCategories;
    final effectiveCategoryId =
        _selectedCategoryId ??
        (availableCategories.isNotEmpty ? availableCategories.first.id : null);
    final loginRequiredMessage = context.tr('로그인이 필요합니다.', 'Please sign in.');
    final saveFailedMessage = context.tr(
      '거래 저장에 실패했습니다.',
      'Failed to save transaction.',
    );

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isIncome
                  ? context.tr('입금내역 추가', 'Add income entry')
                  : context.tr('출금내역 추가', 'Add expense entry'),
              style: AppTextStyles.headlineSmall,
            ),
            const SizedBox(height: 16),
            _EntryField(
              controller: _titleController,
              label: context.tr('항목명', 'Title'),
              hintText: isIncome
                  ? context.tr('예: 월급, 용돈', 'Ex: Salary, allowance')
                  : context.tr('예: 점심, 교통비', 'Ex: Lunch, transit'),
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('분류', 'Category'),
                  style: AppTextStyles.labelMedium,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: effectiveCategoryId,
                  decoration: InputDecoration(
                    hintText: context.tr('분류를 선택하세요', 'Select category'),
                  ),
                  items: availableCategories
                      .map(
                        (c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                      )
                      .toList(),
                  onChanged: availableCategories.isEmpty
                      ? null
                      : (v) => setState(() => _selectedCategoryId = v),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _EntryField(
              controller: _amountController,
              label: context.tr('금액', 'Amount'),
              hintText: context.tr('숫자만 입력', 'Numbers only'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final amount = int.tryParse(
                    _amountController.text.replaceAll(',', ''),
                  );
                  final selectedCategory = availableCategories
                      .where((c) => c.id == effectiveCategoryId)
                      .firstOrNull;
                  if (_titleController.text.trim().isEmpty ||
                      selectedCategory == null ||
                      amount == null ||
                      amount <= 0) {
                    return;
                  }

                  final userId = resolveSignedInUserId(widget.hostContext);
                  if (userId == null) {
                    _showSaveError(context, loginRequiredMessage);
                    return;
                  }
                  final now = DateTime.now();
                  final transactionProvider = widget.hostContext
                      .read<TransactionProvider>();
                  final settings = widget.hostContext.read<SettingsProvider>();
                  final previousExpense = transactionProvider
                      .totalExpenseForMonth(transactionProvider.selectedMonth);

                  try {
                    await transactionProvider.addTransaction(
                      createTransactionDraft(
                        userId: userId,
                        type: widget.type,
                        title: _titleController.text,
                        amount: amount,
                        category: selectedCategory,
                        now: now,
                      ),
                    );
                  } catch (_) {
                    if (!context.mounted) return;
                    _showSaveError(context, saveFailedMessage);
                    return;
                  }
                  if (!context.mounted) return;
                  Navigator.of(context).pop();

                  if (widget.type == TransactionType.expense &&
                      settings.budgetAlert) {
                    final warningLine =
                        (settings.monthlyBudget *
                                (settings.budgetWarningPrimary / 100))
                            .round();
                    final currentExpense = transactionProvider
                        .totalExpenseForMonth(
                          transactionProvider.selectedMonth,
                        );
                    if (previousExpense < warningLine &&
                        currentExpense >= warningLine) {
                      _showBudgetWarningBanner(
                        widget.hostContext,
                        currentExpense: currentExpense,
                        warningThreshold: settings.budgetWarningPrimary,
                        monthlyBudget: settings.monthlyBudget,
                        currency: settings.currency,
                        isEnglish: settings.isEnglish,
                      );
                    }
                  }
                },
                child: Text(
                  isIncome
                      ? context.tr('입금 저장', 'Save income')
                      : context.tr('출금 저장', 'Save expense'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showBudgetWarningBanner(
  BuildContext context, {
  required int currentExpense,
  required int warningThreshold,
  required int monthlyBudget,
  required String currency,
  required bool isEnglish,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  final expenseText = _fmtCurrency(currentExpense, currency, isEnglish);
  final budgetText = _fmtCurrency(monthlyBudget, currency, isEnglish);

  messenger
    ..hideCurrentMaterialBanner()
    ..showMaterialBanner(
      MaterialBanner(
        backgroundColor: const Color(0xFF14171C),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        leading: const Icon(
          Icons.notifications_active_rounded,
          color: AppColors.primaryLight,
        ),
        content: Text(
          isEnglish
              ? 'You reached $warningThreshold% of your budget. $expenseText spent out of $budgetText.'
              : '예산의 $warningThreshold%에 도달했어요. $budgetText 중 $expenseText를 사용했어요.',
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: messenger.hideCurrentMaterialBanner,
            child: Text(
              isEnglish ? 'Close' : '닫기',
              style: AppTextStyles.labelMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

  Future<void>.delayed(
    const Duration(seconds: 3),
    messenger.hideCurrentMaterialBanner,
  );
}

String _fmtCurrency(int amount, String currency, bool isEnglish) {
  final locale = isEnglish ? 'en_US' : 'ko_KR';
  final symbol = switch (currency) {
    'USD' => '\$',
    'JPY' => '¥',
    _ => '₩',
  };
  return NumberFormat.currency(
    locale: locale,
    symbol: symbol,
    decimalDigits: 0,
  ).format(amount);
}

class _EntryField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final TextInputType keyboardType;

  const _EntryField({
    required this.controller,
    required this.label,
    required this.hintText,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelMedium),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(hintText: hintText),
        ),
      ],
    );
  }
}
