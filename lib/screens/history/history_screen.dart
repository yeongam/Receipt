import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/signed_in_user_id.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_preferences_format.dart';
import '../../data/models/transaction.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/settings_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'all';

  final List<String> _filters = ['all', 'expense', 'income'];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final month = provider.selectedMonth;
    final allTransactions = provider.transactionsForMonth(month);
    final visibleTransactions = allTransactions.where((transaction) {
      if (_selectedFilter == 'income') return transaction.isIncome;
      if (_selectedFilter == 'expense') return transaction.isExpense;
      return true;
    }).toList();
    final grouped = _groupByDate(context, visibleTransactions);
    final income = provider.totalIncomeForMonth(month);
    final expense = provider.totalExpenseForMonth(month);
    final balance = provider.balanceForMonth(month);
    final pageBackground = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: Text(
          context.tr('거래 내역', 'Transaction history'),
          style: AppTextStyles.titleLarge.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: pageBackground,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () async {
                    final userId = resolveSignedInUserId(context) ?? '';
                    final prevMonth = DateTime(month.year, month.month - 1);
                    await provider.loadMonth(userId, prevMonth);
                  },
                  icon: const Icon(
                    Icons.chevron_left_rounded,
                    color: AppColors.secondary,
                    size: 28,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 10),
                Text(
                  context.formatMonthYear(month),
                  style: AppTextStyles.titleLarge.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: () async {
                    final userId = resolveSignedInUserId(context) ?? '';
                    final nextMonth = DateTime(month.year, month.month + 1);
                    await provider.loadMonth(userId, nextMonth);
                  },
                  icon: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.secondary,
                    size: 28,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Container(
            color: pageBackground,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 17),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: _MiniStat(
                    label: context.tr('입금', 'Income'),
                    amount: context.formatCurrency(income),
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 1,
                  height: 34,
                  color: Theme.of(context).dividerColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniStat(
                    label: context.tr('출금', 'Expense'),
                    amount: context.formatCurrency(expense),
                    color: AppColors.expense,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 1,
                  height: 34,
                  color: Theme.of(context).dividerColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniStat(
                    label: context.tr('잔액', 'Balance'),
                    amount: context.formatCurrency(balance),
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: pageBackground,
            padding: const EdgeInsets.only(bottom: 13),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (var index = 0; index < _filters.length; index++) ...[
                    if (index > 0) const SizedBox(width: 8),
                    Builder(
                      builder: (context) {
                        final filter = _filters[index];
                        final isSelected = _selectedFilter == filter;
                        return ChoiceChip(
                          label: Text(_filterLabel(context, filter)),
                          selected: isSelected,
                          onSelected: (_) =>
                              setState(() => _selectedFilter = filter),
                          selectedColor: AppColors.primary,
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : Theme.of(context).dividerColor,
                          ),
                          showCheckmark: false,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          labelStyle: AppTextStyles.labelMedium.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.68),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: grouped.entries.map((entry) {
                return _DateGroup(
                  date: entry.key,
                  transactions: entry.value,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

Map<String, List<AppTransaction>> _groupByDate(
  BuildContext context,
  List<AppTransaction> transactions,
) {
  final Map<String, List<AppTransaction>> grouped = {};
  for (final transaction in transactions) {
    final key = context.formatFullDate(transaction.occurredAt);
    grouped.putIfAbsent(key, () => []).add(transaction);
  }
  return grouped;
}

String _filterLabel(BuildContext context, String filter) {
  switch (filter) {
    case 'expense':
      return context.tr('출금', 'Expense');
    case 'income':
      return context.tr('입금', 'Income');
    default:
      return context.tr('전체', 'All');
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.68),
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            amount,
            maxLines: 1,
            style: AppTextStyles.titleMedium.copyWith(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _DateGroup extends StatelessWidget {
  final String date;
  final List<AppTransaction> transactions;

  const _DateGroup({
    required this.date,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    final compactView = context.watch<SettingsProvider>().compactView;
    final dailyTotal = transactions.fold<int>(
      0,
      (sum, transaction) =>
          sum +
          (transaction.isIncome ? transaction.amount : -transaction.amount),
    );
    final isPositive = dailyTotal >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(date, style: AppTextStyles.labelMedium),
              Text(
                '${isPositive ? '+' : '-'}${context.formatCurrency(dailyTotal.abs())}',
                style: AppTextStyles.labelMedium.copyWith(
                  color: isPositive ? AppColors.accent : AppColors.expense,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: List.generate(transactions.length, (index) {
              final transaction = transactions[index];
              final color =
                  transaction.isIncome ? AppColors.accent : AppColors.expense;
              return Column(
                children: [
                  ListTile(
                    dense: compactView,
                    visualDensity: compactView
                        ? const VisualDensity(horizontal: 0, vertical: -2)
                        : VisualDensity.standard,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: compactView ? 0 : 4,
                    ),
                    leading: Container(
                      width: compactView ? 36 : 40,
                      height: compactView ? 36 : 40,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(compactView ? 9 : 10),
                      ),
                      child: Icon(
                        transaction.isIncome
                            ? Icons.south_west_rounded
                            : Icons.north_east_rounded,
                        color: color,
                        size: compactView ? 18 : 20,
                      ),
                    ),
                    title: Text(
                      transaction.title,
                      style: compactView
                          ? AppTextStyles.labelLarge
                          : AppTextStyles.titleSmall,
                    ),
                    subtitle: Text(
                      () {
                        final catName = context
                            .watch<CategoryProvider>()
                            .categoryNameFor(transaction.categoryId);
                        final time =
                            '${transaction.occurredAt.hour.toString().padLeft(2, '0')}:${transaction.occurredAt.minute.toString().padLeft(2, '0')}';
                        return catName.isEmpty ? time : '$catName · $time';
                      }(),
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${transaction.isIncome ? '+' : '-'}${context.formatCurrency(transaction.amount)}',
                          style: (compactView
                                  ? AppTextStyles.labelLarge
                                  : AppTextStyles.titleSmall)
                              .copyWith(
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 2),
                        IconButton(
                          onPressed: () =>
                              _confirmDeleteTransaction(context, transaction),
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.48),
                            size: compactView ? 18 : 20,
                          ),
                          tooltip: context.tr('삭제', 'Delete'),
                          splashRadius: 18,
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                        ),
                      ],
                    ),
                  ),
                  if (index < transactions.length - 1)
                    const Divider(
                      height: 1,
                      indent: 68,
                      color: AppColors.divider,
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteTransaction(
    BuildContext context,
    AppTransaction transaction,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('거래 내역 삭제', 'Delete transaction')),
        content: Text(
          context.tr(
            '${transaction.title} 내역을 삭제할까요?',
            'Delete the ${transaction.title} transaction?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.tr('취소', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.tr('삭제', 'Delete')),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await context.read<TransactionProvider>().deleteTransaction(transaction.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr(
            '${transaction.title} 내역을 삭제했어요.',
            '${transaction.title} has been deleted.',
          ),
        ),
      ),
    );
  }
}
