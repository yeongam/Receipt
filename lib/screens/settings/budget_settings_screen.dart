import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_preferences_format.dart';
import '../../providers/settings_provider.dart';
import 'settings_widgets.dart';

/// Returns (minBudget, maxBudget, divisions, rangeLabel) for the given currency.
({int min, int max, int divisions, String rangeLabel}) _budgetRange(
  String currency,
  bool isEnglish,
) {
  return switch (currency) {
    'USD' => (
        min: 500,
        max: 5000,
        divisions: 9,
        rangeLabel: isEnglish
            ? '\$500 ~ \$5,000 (\$500 unit)'
            : '\$500 ~ \$5,000 (단위 \$500)',
      ),
    'JPY' => (
        min: 50000,
        max: 500000,
        divisions: 9,
        rangeLabel: isEnglish
            ? '¥50,000 ~ ¥500,000 (¥50,000 unit)'
            : '¥50,000 ~ ¥500,000 (단위 ¥50,000)',
      ),
    _ => (
        min: 500000,
        max: 5000000,
        divisions: 9,
        rangeLabel: isEnglish
            ? '₩500,000 ~ ₩5,000,000 (₩500,000 unit)'
            : '50만원 ~ 500만원 (50만원 단위)',
      ),
  };
}

class BudgetSettingsScreen extends StatelessWidget {
  const BudgetSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final range = _budgetRange(settings.currency, settings.isEnglish);

    // Clamp the stored budget to the valid range for the current currency so
    // the Slider never receives a value outside [min, max].
    final clampedBudget =
        settings.monthlyBudget.clamp(range.min, range.max);

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
              value: clampedBudget.toDouble(),
              min: range.min.toDouble(),
              max: range.max.toDouble(),
              divisions: range.divisions,
              activeColor: AppColors.primary,
              onChanged: (value) {
                context.read<SettingsProvider>().updateMonthlyBudget(
                  value.round(),
                );
              },
            ),
            SettingsRow(label: '설정 범위', value: range.rangeLabel),
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
