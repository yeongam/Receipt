import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_preferences_format.dart';
import '../../data/models/transaction.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/settings_provider.dart';
import '../history/history_screen.dart';
import '../settings/settings_screens.dart';
import '../shared/edge_overscroll_background.dart';
import '../shared/transaction_entry_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final settings = context.watch<SettingsProvider>();
    final month = provider.selectedMonth;
    final income = provider.totalIncomeForMonth(month);
    final expense = provider.totalExpenseForMonth(month);
    final balance = provider.balanceForMonth(month);
    final recent = provider.recentTransactions(limit: 5);
    final weeklySummary = _buildWeeklySummary(provider.transactions);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: EdgeOverscrollBackground(
        topColor: AppColors.primary,
        bottomColor: Theme.of(context).scaffoldBackgroundColor,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: AppColors.primary,
              floating: true,
              snap: true,
              elevation: 0,
              titleSpacing: 20,
              title: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.wallet_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      context.tr('통합 지출관리', 'Integrated Expense'),
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleLarge.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              leading: const SizedBox.shrink(),
              leadingWidth: 0,
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SummaryCard(
                    expense: expense,
                    income: income,
                    balance: balance,
                    month: month,
                  ),
                  if (settings.showWeeklySummary) ...[
                    const SizedBox(height: 20),
                    _SectionHeader(
                      title: context.tr('주간 요약', 'Weekly summary'),
                      showMore: false,
                    ),
                    const SizedBox(height: 12),
                    _WeeklySummaryCard(summary: weeklySummary),
                  ],
                  const SizedBox(height: 20),
                  _SectionHeader(
                    title: context.tr('빠른 메뉴', 'Quick actions'),
                    showMore: false,
                  ),
                  const SizedBox(height: 12),
                  _QuickActions(
                    onIncomeTap: () => openTransactionEntrySheet(
                        context, TransactionType.income),
                    onExpenseTap: () => openTransactionEntrySheet(
                        context, TransactionType.expense),
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader(
                    title: context.tr('이번 달 예산', 'This month budget'),
                    onMoreTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => _BudgetOverviewScreen(
                            expense: expense,
                            budget: settings.monthlyBudget,
                            warningThreshold: settings.budgetWarningPrimary,
                            startDayLabel: settings.budgetStartDay,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _BudgetCard(
                    expense: expense,
                    budget: settings.monthlyBudget,
                    warningThreshold: settings.budgetWarningPrimary,
                    startDayLabel: settings.budgetStartDay,
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader(
                    title: context.tr('최근 거래', 'Recent transactions'),
                    onMoreTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const HistoryScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _RecentTransactions(transactions: recent),
                  const SizedBox(height: 92),
                ],
              ),
            ),
          ],
        ),
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
                Text(context.formatMonthYear(month),
                    style: AppTextStyles.labelMedium
                        .copyWith(color: Colors.white70)),
              ],
            ),
            const SizedBox(height: 16),
            Text(context.tr('이번 달 출금', 'This month spending'),
                style: AppTextStyles.bodySmall.copyWith(color: Colors.white60)),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  context.formatCurrency(expense),
                  style: AppTextStyles.amount
                      .copyWith(color: Colors.white, fontSize: 34),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _SummaryChip(
                  icon: Icons.arrow_downward_rounded,
                  label: context.tr('입금', 'Income'),
                  amount: context.formatCurrency(income),
                  color: AppColors.accent,
                ),
                const SizedBox(width: 16),
                Container(width: 1, height: 36, color: Colors.white24),
                const SizedBox(width: 16),
                _SummaryChip(
                  icon: Icons.account_balance_wallet_outlined,
                  label: context.tr('잔액', 'Balance'),
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
                style: AppTextStyles.titleSmall.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool showMore;
  final VoidCallback? onMoreTap;

  const _SectionHeader({
    required this.title,
    this.showMore = true,
    this.onMoreTap,
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
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onMoreTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  context.tr('전체보기', 'See all'),
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BudgetOverviewScreen extends StatelessWidget {
  const _BudgetOverviewScreen({
    required this.expense,
    required this.budget,
    required this.warningThreshold,
    required this.startDayLabel,
  });

  final int expense;
  final int budget;
  final int warningThreshold;
  final String startDayLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(context.tr('이번 달 예산', 'This month budget')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          _BudgetCard(
            expense: expense,
            budget: budget,
            warningThreshold: warningThreshold,
            startDayLabel: startDayLabel,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('예산 관리', 'Budget management'),
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr(
                    '예산 금액, 시작일, 경고 기준은 설정 화면에서 바꿀 수 있어요.',
                    'You can update your budget amount, start day, and warning threshold from settings.',
                  ),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.68),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const BudgetSettingsScreen(),
                        ),
                      );
                    },
                    child: Text(context.tr('예산 설정 열기', 'Open budget settings')),
                  ),
                ),
              ],
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
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
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
                        color: Theme.of(context).colorScheme.onSurface,
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
  final int budget;
  final int warningThreshold;
  final String startDayLabel;

  const _BudgetCard({
    required this.expense,
    required this.budget,
    required this.warningThreshold,
    required this.startDayLabel,
  });

  @override
  Widget build(BuildContext context) {
    final safeBudget = budget <= 0 ? 1 : budget;
    final ratio = (expense / safeBudget).clamp(0.0, 1.0);
    final warningRatio = (warningThreshold / 100).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
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
              Text(context.tr('월 예산', 'Monthly budget'),
                  style: AppTextStyles.bodySmall),
              Text(
                context.tr(
                  '${(ratio * 100).toStringAsFixed(0)}% 사용',
                  '${(ratio * 100).toStringAsFixed(0)}% used',
                ),
                style: AppTextStyles.labelMedium.copyWith(
                  color: ratio >= warningRatio
                      ? AppColors.expense
                      : AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            startDayLabel,
            style: AppTextStyles.labelSmall.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(context.formatCurrency(expense),
                  style: AppTextStyles.amountSmall),
              Text(' / ${context.formatCurrency(budget)}',
                  style: AppTextStyles.bodySmall),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                ratio >= warningRatio ? AppColors.expense : AppColors.primary,
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklySummary {
  final int income;
  final int expense;
  final int net;
  final int count;
  final DateTime start;
  final DateTime end;

  const _WeeklySummary({
    required this.income,
    required this.expense,
    required this.net,
    required this.count,
    required this.start,
    required this.end,
  });
}

_WeeklySummary _buildWeeklySummary(List<AppTransaction> transactions) {
  if (transactions.isEmpty) {
    final now = DateTime.now();
    return _WeeklySummary(
      income: 0,
      expense: 0,
      net: 0,
      count: 0,
      start: now.subtract(const Duration(days: 6)),
      end: now,
    );
  }

  final sorted = [...transactions]
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  final end = sorted.first.occurredAt;
  final start =
      DateTime(end.year, end.month, end.day).subtract(const Duration(days: 6));
  final weekItems = sorted.where((item) {
    final day = DateTime(
        item.occurredAt.year, item.occurredAt.month, item.occurredAt.day);
    return !day.isBefore(start) && !day.isAfter(end);
  }).toList();

  final income = weekItems
      .where((item) => item.isIncome)
      .fold<int>(0, (sum, item) => sum + item.amount);
  final expense = weekItems
      .where((item) => item.isExpense)
      .fold<int>(0, (sum, item) => sum + item.amount);

  return _WeeklySummary(
    income: income,
    expense: expense,
    net: income - expense,
    count: weekItems.length,
    start: start,
    end: end,
  );
}

class _WeeklySummaryCard extends StatelessWidget {
  final _WeeklySummary summary;

  const _WeeklySummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final netPositive = summary.net >= 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${summary.start.month}/${summary.start.day} - ${summary.end.month}/${summary.end.day}',
            style: AppTextStyles.labelMedium.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            context.tr(
              '이번 주 순변동 ${context.formatCurrency(summary.net.abs())}',
              'Net change ${context.formatCurrency(summary.net.abs())}',
            ),
            style: AppTextStyles.titleLarge.copyWith(
              color: netPositive ? AppColors.accent : AppColors.expense,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _WeeklyStat(
                  label: context.tr('입금', 'Income'),
                  value: context.formatCurrency(summary.income),
                  color: AppColors.accent,
                ),
              ),
              Expanded(
                child: _WeeklyStat(
                  label: context.tr('출금', 'Expense'),
                  value: context.formatCurrency(summary.expense),
                  color: AppColors.expense,
                ),
              ),
              Expanded(
                child: _WeeklyStat(
                  label: context.tr('기록 수', 'Entries'),
                  value: '${summary.count}',
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeeklyStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _WeeklyStat({
    required this.label,
    required this.value,
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
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.62),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.titleSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _RecentTransactions extends StatelessWidget {
  final List<AppTransaction> transactions;

  const _RecentTransactions({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final compactView = context.watch<SettingsProvider>().compactView;
    return Container(
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
          return Column(
            children: [
              _TransactionTile(
                transaction: transaction,
                compactView: compactView,
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
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final AppTransaction transaction;
  final bool compactView;

  const _TransactionTile({
    required this.transaction,
    required this.compactView,
  });

  @override
  Widget build(BuildContext context) {
    final color = transaction.isIncome ? AppColors.accent : AppColors.expense;
    final sign = transaction.isIncome ? '+' : '-';

    return ListTile(
      dense: compactView,
      visualDensity: compactView
          ? const VisualDensity(horizontal: 0, vertical: -2)
          : VisualDensity.standard,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: compactView ? 0 : 6,
      ),
      leading: Container(
        width: compactView ? 38 : 44,
        height: compactView ? 38 : 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(compactView ? 10 : 12),
        ),
        child: Icon(
          transaction.isIncome
              ? Icons.south_west_rounded
              : Icons.north_east_rounded,
          color: color,
          size: compactView ? 20 : 22,
        ),
      ),
      title: Text(
        transaction.title,
        style:
            compactView ? AppTextStyles.titleSmall : AppTextStyles.titleMedium,
      ),
      subtitle: Text(
        '${transaction.categoryId ?? ''} · ${transaction.occurredAt.month}/${transaction.occurredAt.day}',
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
      trailing: Text(
        '$sign${context.formatCurrency(transaction.amount)}',
        style:
            (compactView ? AppTextStyles.titleSmall : AppTextStyles.titleMedium)
                .copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
