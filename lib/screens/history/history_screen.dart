import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/supabase/supabase_config.dart';
import '../../core/utils/amount_format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/transaction.dart';
import '../../providers/settings_provider.dart';
import '../../providers/transaction_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late DateTime _selectedMonth;
  String _selectedFilter = '전체';

  final List<String> _filters = ['전체', '출금', '입금'];

  @override
  void initState() {
    super.initState();
    _selectedMonth = context.read<TransactionProvider>().selectedMonth;
  }

  void _changeMonth(int delta) {
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + delta);
    setState(() => _selectedMonth = next);
    final userId = SupabaseConfig.client.auth.currentUser?.id ?? '';
    context.read<TransactionProvider>().loadMonth(userId, next, select: false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final settings = context.watch<SettingsProvider>();
    final month = _selectedMonth;
    final allTransactions = provider.transactionsForMonth(month);
    final visibleTransactions = allTransactions.where((transaction) {
      if (_selectedFilter == '입금') return transaction.isIncome;
      if (_selectedFilter == '출금') return transaction.isExpense;
      return true;
    }).toList();
    final grouped = _groupByDate(visibleTransactions);
    final income = provider.totalIncomeForMonth(month);
    final expense = provider.totalExpenseForMonth(month);
    final balance = provider.balanceForMonth(month);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('거래 내역'),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => _changeMonth(-1),
                  icon: const Icon(Icons.chevron_left_rounded,
                      color: AppColors.secondary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                Text('${_selectedMonth.year}년 ${_selectedMonth.month}월',
                    style: AppTextStyles.titleLarge),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _changeMonth(1),
                  icon: const Icon(Icons.chevron_right_rounded,
                      color: AppColors.secondary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                _MiniStat(label: '입금', amount: formatAmount(income), color: AppColors.accent),
                const SizedBox(width: 16),
                Container(width: 1, height: 32, color: AppColors.border),
                const SizedBox(width: 16),
                _MiniStat(label: '출금', amount: formatAmount(expense), color: AppColors.expense),
                const SizedBox(width: 16),
                Container(width: 1, height: 32, color: AppColors.border),
                const SizedBox(width: 16),
                _MiniStat(label: '잔액', amount: formatAmount(balance), color: AppColors.primary),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedFilter = filter),
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.background,
                      labelStyle: AppTextStyles.labelMedium.copyWith(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: grouped.entries.map((entry) {
                return _DateGroup(
                  date: entry.key,
                  transactions: entry.value,
                  compact: settings.compactView,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

Map<String, List<AppTransaction>> _groupByDate(List<AppTransaction> transactions) {
  final Map<String, List<AppTransaction>> grouped = {};
  for (final transaction in transactions) {
    final key =
        '${transaction.occurredAt.year}년 ${transaction.occurredAt.month}월 ${transaction.occurredAt.day}일';
    grouped.putIfAbsent(key, () => []).add(transaction);
  }
  return grouped;
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
        Text(label,
            style:
                AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(amount,
            style: AppTextStyles.titleSmall
                .copyWith(color: color, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _DateGroup extends StatelessWidget {
  final String date;
  final List<AppTransaction> transactions;
  final bool compact;

  const _DateGroup({
    required this.date,
    required this.transactions,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final dailyTotal = transactions.fold<int>(
      0,
      (sum, t) => sum + (t.isIncome ? t.amount : -t.amount),
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
                '${isPositive ? '+' : '-'}${formatAmount(dailyTotal.abs())}원',
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
            color: Colors.white,
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
                    dense: compact,
                    visualDensity: compact
                        ? const VisualDensity(vertical: -2)
                        : VisualDensity.standard,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: compact ? 1 : 4,
                    ),
                    leading: Container(
                      width: compact ? 36 : 40,
                      height: compact ? 36 : 40,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        transaction.isIncome
                            ? Icons.south_west_rounded
                            : Icons.north_east_rounded,
                        color: color,
                        size: compact ? 18 : 20,
                      ),
                    ),
                    title: Text(transaction.title, style: AppTextStyles.titleSmall),
                    subtitle: Text(
                      '${transaction.occurredAt.hour.toString().padLeft(2, '0')}:${transaction.occurredAt.minute.toString().padLeft(2, '0')}',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    trailing: Text(
                      '${transaction.isIncome ? '+' : '-'}${formatAmount(transaction.amount)}원',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (index < transactions.length - 1)
                    const Divider(height: 1, indent: 68, color: AppColors.divider),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

