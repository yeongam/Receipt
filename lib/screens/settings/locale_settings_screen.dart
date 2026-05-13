import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';
import 'settings_widgets.dart';

class LocaleSettingsScreen extends StatelessWidget {
  const LocaleSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return SettingsScaffold(
      title: '언어 / 통화 설정',
      children: [
        SettingsCard(
          title: '현재 설정',
          children: [
            DropdownButtonFormField<String>(
              initialValue: settings.language,
              decoration: const InputDecoration(labelText: '언어'),
              items: const ['한국어', 'English']
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                context.read<SettingsProvider>().updateLocale(language: value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: settings.currency,
              decoration: const InputDecoration(labelText: '통화'),
              items: const ['KRW', 'USD', 'JPY']
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                context.read<SettingsProvider>().updateLocale(currency: value);
              },
            ),
          ],
        ),
      ],
    );
  }
}
