import 'package:flutter/material.dart';

import 'settings_widgets.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsScaffold(
      title: '이용약관',
      children: [
        SettingsCard(
          title: '안내',
          children: [
            BulletText('서비스 이용 시 사용자가 입력한 가계부 데이터는 개인 관리 목적에 사용됩니다.'),
            BulletText('허위 정보 입력으로 인한 손실은 사용자 책임입니다.'),
          ],
        ),
      ],
    );
  }
}
