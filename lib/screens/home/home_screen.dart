import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_preferences_format.dart';
import '../../data/models/transaction.dart';
import '../../providers/settings_provider.dart';
import '../../providers/transaction_provider.dart';
import '../shared/transaction_entry_sheet.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback? onNavigateToHistory;
  const HomeScreen({super.key, this.onNavigateToHistory});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final settings = context.watch<SettingsProvider>();
    final month = provider.selectedMonth;
    final income = provider.totalIncomeForMonth(month);
    final expense = provider.totalExpenseForMonth(month);
    final balance = provider.balanceForMonth(month);
    final recent =
        provider.recentTransactions(limit: settings.compactView ? 7 : 5);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.white,
            floating: true,
            snap: true,
            elevation: 0,
            leadingWidth: 160,
            leading: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.wallet_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '통합 지출관리',
                    style: AppTextStyles.titleLarge
                        .copyWith(color: AppColors.secondary),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (settings.showWeeklySummary) ...[
                  _SummaryCard(
                    expense: expense,
                    income: income,
                    balance: balance,
                    month: month,
                  ),
                  const SizedBox(height: 20),
                ],
                const _SectionHeader(title: '빠른 메뉴', showMore: false),
                const SizedBox(height: 12),
                _QuickActions(
                  onIncomeTap: () => openTransactionEntrySheet(context, TransactionType.income),
                  onExpenseTap: () => openTransactionEntrySheet(context, TransactionType.expense),
                ),
                const SizedBox(height: 24),
                const _SectionHeader(title: '이번 달 예산'),
                const SizedBox(height: 12),
                _BudgetCard(expense: expense),
                const SizedBox(height: 24),
                _SectionHeader(title: '최근 거래', onShowMore: onNavigateToHistory),
                const SizedBox(height: 12),
                _RecentTransactions(
                  transactions: recent,
                  compact: settings.compactView,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int expense;
  final int income;
  final int balance;
  final DateTime month;

  const _SummaryCard({
    required this.expense,
    required this.income,
    required this.balance,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3D5AFE), Color(0xFF14213D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    color: Colors.white54, size: 14),
                const SizedBox(width: 6),
                Text('${month.year}년 ${month.month}월',
                    style: AppTextStyles.labelMedium
                        .copyWith(color: Colors.white70)),
              ],
            ),
            const SizedBox(height: 16),
            Text('이번 달 출금',
                style:
                    AppTextStyles.bodySmall.copyWith(color: Colors.white60)),
            const SizedBox(height: 4),
            Text(
              context.formatCurrency(expense),
              style: AppTextStyles.amount
                  .copyWith(color: Colors.white, fontSize: 34),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _SummaryChip(
                  icon: Icons.arrow_downward_rounded,
                  label: '입금',
                  amount: context.formatCurrency(income),
                  color: AppColors.accent,
                ),
                const SizedBox(width: 16),
                Container(width: 1, height: 36, color: Colors.white24),
                const SizedBox(width: 16),
                _SummaryChip(
                  icon: Icons.account_balance_wallet_outlined,
                  label: '잔액',
                  amount: context.formatCurrency(balance),
                  color: Colors.white,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String amount;
  final Color color;

  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    AppTextStyles.labelSmall.copyWith(color: Colors.white54)),
            Text(amount,
                style: AppTextStyles.titleSmall
                    .copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool showMore;
  final VoidCallback? onShowMore;

  const _SectionHeader({
    required this.title,
    this.showMore = true,
    this.onShowMore,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.titleLarge),
          if (showMore)
            GestureDetector(
              onTap: onShowMore,
              child: Text(
                '전체보기',
                style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final VoidCallback onIncomeTap;
  final VoidCallback onExpenseTap;

  const _QuickActions({
    required this.onIncomeTap,
    required this.onExpenseTap,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        icon: Icons.south_west_rounded,
        label: '입금내역',
        color: AppColors.accent,
        bg: AppColors.accentLight,
        onTap: onIncomeTap,
      ),
      (
        icon: Icons.north_east_rounded,
        label: '출금내역',
        color: AppColors.expense,
        bg: AppColors.expenseLight,
        onTap: onExpenseTap,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: actions.map((action) {
          return Expanded(
            child: GestureDetector(
              onTap: action.onTap,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 18),
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
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: action.bg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(action.icon, color: action.color, size: 24),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      action.label,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final int expense;

  const _BudgetCard({required this.expense});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final total = settings.monthlyBudget;
    final ratio = total == 0 ? 0.0 : (expense / total).clamp(0.0, 1.0);
    final warningRatio = settings.budgetWarningPrimary / 100;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('월 예산', style: AppTextStyles.bodySmall),
              Text(
                '${(ratio * 100).toStringAsFixed(0)}% 사용',
                style: AppTextStyles.labelMedium.copyWith(
                  color: ratio > warningRatio ? AppColors.expense : AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(context.formatCurrency(expense),
                  style: AppTextStyles.amountSmall),
              Text(' / ${context.formatCurrency(total)}', style: AppTextStyles.bodySmall),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(
                ratio > warningRatio ? AppColors.expense : AppColors.primary,
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentTransactions extends StatelessWidget {
  final List<AppTransaction> transactions;
  final bool compact;

  const _RecentTransactions({
    required this.transactions,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          return Column(
            children: [
              _TransactionTile(
                transaction: transaction,
                compact: compact,
              ),
              if (index < transactions.length - 1)
                const Divider(height: 1, indent: 68, color: AppColors.divider),
            ],
          );
        }),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final AppTransaction transaction;
  final bool compact;

  const _TransactionTile({
    required this.transaction,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final color = transaction.isIncome ? AppColors.accent : AppColors.expense;
    final sign = transaction.isIncome ? '+' : '-';

    return ListTile(
      dense: compact,
      visualDensity:
          compact ? const VisualDensity(vertical: -2) : VisualDensity.standard,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: compact ? 2 : 6,
      ),
      leading: Container(
        width: compact ? 40 : 44,
        height: compact ? 40 : 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          transaction.isIncome
              ? Icons.south_west_rounded
              : Icons.north_east_rounded,
          color: color,
          size: compact ? 20 : 22,
        ),
      ),
      title: Text(transaction.title, style: AppTextStyles.titleMedium),
      subtitle: Text(
        '${transaction.occurredAt.month}/${transaction.occurredAt.day}',
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
      trailing: Text(
        '$sign${context.formatCurrency(transaction.amount)}',
        style: AppTextStyles.titleMedium.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

