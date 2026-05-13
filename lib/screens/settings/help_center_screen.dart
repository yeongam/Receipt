import 'package:flutter/material.dart';

import 'settings_widgets.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsScaffold(
      title: '도움말',
      children: [
        SettingsCard(
          title: '자주 묻는 질문',
          children: [
            BulletText('입금/출금은 홈 화면 빠른 메뉴에서 바로 추가할 수 있어요.'),
            BulletText('고정지출 관리는 마이페이지 또는 알림 관리 화면에서 설정할 수 있어요.'),
            BulletText('리포트 화면에서는 월별 지출 흐름과 분류별 비중을 확인할 수 있어요.'),
          ],
        ),
      ],
    );
  }
}
