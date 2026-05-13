import 'package:flutter/material.dart';

import 'settings_widgets.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsScaffold(
      title: '개인정보처리방침',
      children: [
        SettingsCard(
          title: '수집 항목',
          children: [
            BulletText('이메일, 프로필 정보, 사용자가 직접 입력한 입출금 데이터'),
            BulletText('서비스 품질 향상을 위한 최소한의 사용 로그'),
          ],
        ),
      ],
    );
  }
}
