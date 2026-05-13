import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_preferences_format.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/transaction_provider.dart';
import '../notification/notification_screen.dart';
import '../settings/settings_screens.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final settings = context.watch<SettingsProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final authProvider = context.watch<AuthProvider>();
    final month = provider.selectedMonth;
    final transactions = provider.transactionsForMonth(month);
    final totalExpense = provider.totalExpenseForMonth(month);
    final totalIncome = provider.totalIncomeForMonth(month);
    final savingRate = totalIncome == 0
        ? 0.0
        : (((totalIncome - totalExpense) / totalIncome) * 100)
            .clamp(0, 100)
            .toDouble();
    final userName = authProvider.user?.name ?? '';
    final userUsername = authProvider.user?.username ?? '';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: Text(
          context.tr('마이페이지', 'My Page'),
          style: AppTextStyles.titleLarge.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                  builder: (_) => const AppPreferencesScreen()),
            ),
            icon: const Icon(Icons.settings_outlined, color: AppColors.primary),
          ),
        ],
      ),
      body: ListView(
        children: [
          _ProfileHeader(name: userName, profileId: userUsername),
          const SizedBox(height: 16),
          _StatsRow(
            totalTransactions: transactions.length,
            totalExpense: totalExpense,
            savingRate: savingRate,
          ),
          const SizedBox(height: 16),
          _MenuSection(
            title: context.tr('가계부 설정', 'Ledger settings'),
            items: [
              _MenuItem(
                icon: Icons.savings_outlined,
                label: context.tr('예산 설정', 'Budget settings'),
                trailing: context.formatCurrency(settings.monthlyBudget),
                onTap: (context) => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const BudgetSettingsScreen()),
                ),
              ),
              _MenuItem(
                icon: Icons.receipt_long_outlined,
                label: context.tr('고정지출 관리', 'Fixed expenses'),
                onTap: (context) => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const NotificationScreen()),
                ),
              ),
              _MenuItem(
                icon: Icons.category_outlined,
                label: context.tr('분류 관리', 'Categories'),
                trailing: context.tr(
                  '${categoryProvider.categories.length}개',
                  '${categoryProvider.categories.length}',
                ),
                onTap: (context) => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const CategorySettingsScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MenuSection(
            title: context.tr('앱 설정', 'App settings'),
            items: [
              _MenuItem(
                icon: Icons.palette_outlined,
                label: context.tr('화면 / 테마 설정', 'Display / Theme'),
                trailing: settings.themeLabel,
                onTap: (context) => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const AppPreferencesScreen()),
                ),
              ),
              _MenuItem(
                icon: Icons.language_outlined,
                label: context.tr('언어 / 통화 설정', 'Language / Currency'),
                trailing: '${settings.language} · ${settings.currency}',
                onTap: (context) => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const LocaleSettingsScreen()),
                ),
              ),
              _MenuItem(
                icon: Icons.lock_outline_rounded,
                label: context.tr('보안 설정', 'Security'),
                onTap: (context) => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const SecuritySettingsScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MenuSection(
            title: context.tr('앱 정보', 'App info'),
            items: [
              _MenuItem(
                icon: Icons.info_outline_rounded,
                label: context.tr('앱 버전', 'App version'),
                trailing: 'v1.0.0',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton(
              onPressed: () => context.read<AuthProvider>().signOut(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.expense,
                side: const BorderSide(color: AppColors.expense),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                context.tr('로그아웃', 'Log out'),
                style: AppTextStyles.button.copyWith(color: AppColors.expense),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String profileId;

  const _ProfileHeader({required this.name, required this.profileId});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0] : '?';

    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(24),
      child: Row(children: [
        Container(
          width: 70,
          height: 70,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              initial,
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: AppTextStyles.headlineSmall),
            const SizedBox(height: 4),
            Text(
              profileId,
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.68),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                context.tr('가계부 사용자', 'Ledger user'),
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int totalTransactions;
  final int totalExpense;
  final double savingRate;

  const _StatsRow({
    required this.totalTransactions,
    required this.totalExpense,
    required this.savingRate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      child: Row(children: [
        _StatItem(
          value: context.tr('$totalTransactions건', '$totalTransactions'),
          label: context.tr('총 거래', 'Transactions'),
        ),
        _divider(context),
        _StatItem(
          value: context.formatCurrency(totalExpense, compact: true),
          label: context.tr('이번 달 지출', 'Spent this month'),
        ),
        _divider(context),
        _StatItem(
          value: '${savingRate.toStringAsFixed(1)}%',
          label: context.tr('저축률', 'Savings rate'),
        ),
      ]),
    );
  }

  Widget _divider(BuildContext context) =>
      Container(width: 1, height: 36, color: Theme.of(context).dividerColor);
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Text(value,
            style:
                AppTextStyles.headlineSmall.copyWith(color: AppColors.primary)),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.bodySmall),
      ]),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;

  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: Text(
          title,
          style: AppTextStyles.labelMedium.copyWith(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.68),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
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
          children: List.generate(items.length, (index) {
            return Column(children: [
              _MenuItemTile(item: items[index]),
              if (index < items.length - 1)
                Divider(
                    height: 1,
                    indent: 52,
                    color: Theme.of(context).dividerColor),
            ]);
          }),
        ),
      ),
    ]);
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String? trailing;
  final void Function(BuildContext context)? onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
  });
}

class _MenuItemTile extends StatelessWidget {
  final _MenuItem item;

  const _MenuItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(item.icon, color: AppColors.primary, size: 18),
      ),
      title: Text(item.label, style: AppTextStyles.titleSmall),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (item.trailing != null)
          Text(
            item.trailing!,
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.68),
            ),
          ),
        const SizedBox(width: 4),
        Icon(
          Icons.chevron_right_rounded,
          color:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.68),
          size: 18,
        ),
      ]),
      onTap: item.onTap == null ? null : () => item.onTap!(context),
    );
  }
}
