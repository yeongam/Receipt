import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_preferences_format.dart';
import '../../providers/settings_provider.dart';
import 'settings_widgets.dart';

class BudgetSettingsScreen extends StatelessWidget {
  const BudgetSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return SettingsScaffold(
      title: '예산 설정',
      children: [
        SettingsCard(
          title: '월 예산',
          children: [
            SettingsRow(
              label: '현재 예산',
              value: context.formatCurrency(settings.monthlyBudget),
            ),
            const SizedBox(height: 8),
            Slider(
              value: settings.monthlyBudget.toDouble(),
              min: 500000,
              max: 5000000,
              divisions: 9,
              activeColor: AppColors.primary,
              onChanged: (value) {
                context.read<SettingsProvider>().updateMonthlyBudget(
                  value.round(),
                );
              },
            ),
            const SettingsRow(label: '설정 범위', value: '50만원 ~ 500만원 (500,000원 단위)'),
            SettingsRow(label: '예산 시작일', value: settings.budgetStartDay),
            SettingsRow(
              label: '예산 경고',
              value:
                  '${settings.budgetWarningPrimary}%, ${settings.budgetWarningSecondary}%',
            ),
          ],
        ),
      ],
    );
  }
}
