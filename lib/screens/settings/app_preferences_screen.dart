import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';
import 'settings_widgets.dart';

class AppPreferencesScreen extends StatelessWidget {
  const AppPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return SettingsScaffold(
      title: '화면 / 테마 설정',
      children: [
        SettingsCard(
          title: '기본 표시',
          children: [
            DropdownButtonFormField<String>(
              initialValue: settings.themeLabel,
              decoration: const InputDecoration(labelText: '테마'),
              items: const ['라이트', '다크']
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                context.read<SettingsProvider>().updatePreferences(
                  themeLabel: value,
                );
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: settings.startScreen,
              decoration: const InputDecoration(labelText: '첫 화면'),
              items: const ['홈', '내역', '리포트', '알림', '마이']
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                context.read<SettingsProvider>().updatePreferences(
                  startScreen: value,
                );
              },
            ),
          ],
        ),
        SwitchCard(
          title: '컴팩트 목록 보기',
          subtitle: '거래 목록에서 한 화면에 더 많은 항목을 보여줘요.',
          value: settings.compactView,
          onChanged: (value) {
            context.read<SettingsProvider>().updatePreferences(
              compactView: value,
            );
          },
        ),
        SwitchCard(
          title: '주간 요약 카드 표시',
          subtitle: '홈 화면에 요약 카드를 유지해요.',
          value: settings.showWeeklySummary,
          onChanged: (value) {
            context.read<SettingsProvider>().updatePreferences(
              showWeeklySummary: value,
            );
          },
        ),
      ],
    );
  }
}
