import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';
import 'settings_widgets.dart';

class AlertSettingsScreen extends StatelessWidget {
  const AlertSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return SettingsScaffold(
      title: '알림 설정',
      children: [
        SwitchCard(
          title: '예산 초과 알림',
          subtitle: '예산의 80%와 100% 도달 시 알려줘요.',
          value: settings.budgetAlert,
          onChanged: (value) {
            context.read<SettingsProvider>().updateAlerts(budgetAlert: value);
          },
        ),
        SwitchCard(
          title: '고정지출 예정 알림',
          subtitle: '자동 차감 하루 전에 알려줘요.',
          value: settings.fixedExpenseAlert,
          onChanged: (value) {
            context.read<SettingsProvider>().updateAlerts(
              fixedExpenseAlert: value,
            );
          },
        ),
        SwitchCard(
          title: '일일 요약 알림',
          subtitle: '하루를 마감하기 전에 입력을 잊지 않게 도와줘요.',
          value: settings.reminderAlert,
          onChanged: (value) {
            context.read<SettingsProvider>().updateAlerts(reminderAlert: value);
          },
        ),
      ],
    );
  }
}
