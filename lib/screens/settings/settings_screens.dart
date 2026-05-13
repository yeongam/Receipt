import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/auth/signed_in_user_id.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/category.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/settings_provider.dart';
import '../shared/pin_pad.dart';

class SettingsScaffold extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsScaffold({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text(title)),
      body: ListView(padding: const EdgeInsets.all(16), children: children),
    );
  }
}

class BudgetSettingsScreen extends StatelessWidget {
  const BudgetSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return SettingsScaffold(
      title: '예산 설정',
      children: [
        _SettingsCard(
          title: '월 예산',
          children: [
            _SettingsRow(
              label: '현재 예산',
              value: '${_formatAmount(settings.monthlyBudget, isEnglish: settings.isEnglish)}원',
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
            const _SettingsRow(label: '설정 범위', value: '50만원 ~ 500만원 (500,000원 단위)'),
            _SettingsRow(label: '예산 시작일', value: settings.budgetStartDay),
            _SettingsRow(
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

class CategorySettingsScreen extends StatelessWidget {
  const CategorySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider?>();
    final categoryProvider = context.watch<CategoryProvider>();
    final userId = authProvider?.user?.id ?? resolveSignedInUserId(context) ?? '';

    return SettingsScaffold(
      title: '분류 관리',
      children: [
        _CategoryCard(
          title: '출금 분류',
          categories: categoryProvider.expenseCategories,
          onAdd: (value) => _addCategory(
            context,
            userId: userId,
            name: value,
            type: 'expense',
          ),
          onRemove: (value) =>
              context.read<CategoryProvider>().deleteCategory(value.id),
        ),
        _CategoryCard(
          title: '입금 분류',
          categories: categoryProvider.incomeCategories,
          onAdd: (value) => _addCategory(
            context,
            userId: userId,
            name: value,
            type: 'income',
          ),
          onRemove: (value) =>
              context.read<CategoryProvider>().deleteCategory(value.id),
        ),
      ],
    );
  }
}

Future<void> _addCategory(
  BuildContext context, {
  required String userId,
  required String name,
  required String type,
}) async {
  final trimmed = name.trim();
  if (trimmed.isEmpty || userId.isEmpty) return;

  final existing = context.read<CategoryProvider>().categories.any(
    (category) => category.type == type && category.name == trimmed,
  );
  if (existing) return;

  await context.read<CategoryProvider>().addCategory(
    AppCategory(
      id: '',
      userId: userId,
      name: trimmed,
      type: type,
      icon: type == 'income' ? 'payments' : 'category',
      colorHex: type == 'income' ? '#29B6F6' : '#607D8B',
      isDefault: false,
      createdAt: DateTime.now(),
    ),
  );
}

class AlertSettingsScreen extends StatelessWidget {
  const AlertSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return SettingsScaffold(
      title: '알림 설정',
      children: [
        _SwitchCard(
          title: '예산 초과 알림',
          subtitle: '예산의 80%와 100% 도달 시 알려줘요.',
          value: settings.budgetAlert,
          onChanged: (value) {
            context.read<SettingsProvider>().updateAlerts(budgetAlert: value);
          },
        ),
        _SwitchCard(
          title: '고정지출 예정 알림',
          subtitle: '자동 차감 하루 전에 알려줘요.',
          value: settings.fixedExpenseAlert,
          onChanged: (value) {
            context.read<SettingsProvider>().updateAlerts(
              fixedExpenseAlert: value,
            );
          },
        ),
        _SwitchCard(
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

class LocaleSettingsScreen extends StatelessWidget {
  const LocaleSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return SettingsScaffold(
      title: '언어 / 통화 설정',
      children: [
        _SettingsCard(
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

class AppPreferencesScreen extends StatelessWidget {
  const AppPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return SettingsScaffold(
      title: '화면 / 테마 설정',
      children: [
        _SettingsCard(
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
        _SwitchCard(
          title: '컴팩트 목록 보기',
          subtitle: '거래 목록에서 한 화면에 더 많은 항목을 보여줘요.',
          value: settings.compactView,
          onChanged: (value) {
            context.read<SettingsProvider>().updatePreferences(
              compactView: value,
            );
          },
        ),
        _SwitchCard(
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

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  Future<void> _showPinSetup() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _PinSetupDialog(),
    );
  }

  Future<void> _saveSecurity({bool? lockOnLaunch, bool? biometric}) async {
    try {
      await context.read<SettingsProvider>().updateSecurity(
        lockOnLaunch: lockOnLaunch,
        biometric: biometric,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('설정 저장에 실패했습니다. 다시 시도해 주세요.')),
      );
    }
  }

  Future<void> _onLockOnLaunchChanged(bool value) async {
    if (value) {
      if (context.read<SettingsProvider>().hasAppLock) {
        await _saveSecurity(lockOnLaunch: true);
      } else {
        await _showPinSetup();
      }
    } else {
      await _saveSecurity(lockOnLaunch: false);
    }
  }

  Future<void> _onBiometricChanged(bool value) async {
    if (value && !context.read<SettingsProvider>().hasAppLock) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text('생체 인증을 사용하려면 먼저 앱 잠금 PIN을 설정하세요.'),
        ),
      );
      return;
    }
    await _saveSecurity(biometric: value);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return SettingsScaffold(
      title: '보안 설정',
      children: [
        _SwitchCard(
          title: '앱 실행 잠금',
          subtitle: '앱을 열 때 비밀번호나 생체 인증을 사용해요.',
          value: settings.lockOnLaunch,
          onChanged: _onLockOnLaunchChanged,
        ),
        _SwitchCard(
          title: '생체 인증 사용',
          subtitle: 'Face ID 또는 지문 인증을 사용해요.',
          value: settings.biometric,
          onChanged: _onBiometricChanged,
        ),
      ],
    );
  }
}

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsScaffold(
      title: '도움말',
      children: [
        _SettingsCard(
          title: '자주 묻는 질문',
          children: [
            _BulletText('입금/출금은 홈 화면 빠른 메뉴에서 바로 추가할 수 있어요.'),
            _BulletText('고정지출 관리는 마이페이지 또는 알림 관리 화면에서 설정할 수 있어요.'),
            _BulletText('리포트 화면에서는 월별 지출 흐름과 분류별 비중을 확인할 수 있어요.'),
          ],
        ),
      ],
    );
  }
}

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsScaffold(
      title: '이용약관',
      children: [
        _SettingsCard(
          title: '안내',
          children: [
            _BulletText('서비스 이용 시 사용자가 입력한 가계부 데이터는 개인 관리 목적에 사용됩니다.'),
            _BulletText('허위 정보 입력으로 인한 손실은 사용자 책임입니다.'),
          ],
        ),
      ],
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsScaffold(
      title: '개인정보처리방침',
      children: [
        _SettingsCard(
          title: '수집 항목',
          children: [
            _BulletText('이메일, 프로필 정보, 사용자가 직접 입력한 입출금 데이터'),
            _BulletText('서비스 품질 향상을 위한 최소한의 사용 로그'),
          ],
        ),
      ],
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final String title;
  final List<AppCategory> categories;
  final Future<void> Function(String value) onAdd;
  final Future<void> Function(AppCategory category) onRemove;

  const _CategoryCard({
    required this.title,
    required this.categories,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: widget.title,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.categories
              .map(
                (category) => Chip(
                  label: Text(category.name),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => widget.onRemove(category),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(hintText: '새 분류 입력'),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () async {
                final focusScope = FocusScope.of(context);
                await widget.onAdd(_controller.text);
                _controller.clear();
                focusScope.unfocus();
              },
              child: const Text('추가'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.titleMedium),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String label;
  final String value;

  const _SettingsRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletText extends StatelessWidget {
  final String text;

  const _BulletText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 7),
            child: Icon(Icons.circle, size: 6, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleSmall),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _PinSetupDialog extends StatefulWidget {
  const _PinSetupDialog();

  @override
  State<_PinSetupDialog> createState() => _PinSetupDialogState();
}

class _PinSetupDialogState extends State<_PinSetupDialog> {
  String _pin = '';
  String _confirmPin = '';
  bool _confirming = false;
  bool _mismatch = false;
  bool _saving = false;

  void _onKey(String digit) {
    if (_saving) return;
    bool shouldSave = false;
    setState(() {
      _mismatch = false;
      if (!_confirming) {
        if (_pin.length < 6) {
          _pin += digit;
          if (_pin.length == 6) _confirming = true;
        }
      } else {
        if (_confirmPin.length < 6) {
          _confirmPin += digit;
          if (_confirmPin.length == 6) shouldSave = true;
        }
      }
    });
    if (shouldSave) _save();
  }

  void _onDelete() {
    if (_saving) return;
    setState(() {
      if (!_confirming) {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        }
      }
    });
  }

  Future<void> _save() async {
    if (_pin != _confirmPin) {
      setState(() {
        _mismatch = true;
        _confirmPin = '';
        _confirming = false;
      });
      return;
    }
    final pinToSave = _pin;
    setState(() {
      _saving = true;
      _pin = '';
      _confirmPin = '';
    });
    try {
      final provider = context.read<SettingsProvider>();
      await provider.setAppLockPasscode(pinToSave);
      final recoveryCode = provider.consumeRecoveryCode();
      await provider.updateSecurity(lockOnLaunch: true);
      if (!mounted) return;
      Navigator.of(context).pop();
      if (recoveryCode != null) {
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => _RecoveryCodeDisplayDialog(code: recoveryCode),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('PIN 저장에 실패했습니다. 다시 시도해 주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayPin = _confirming ? _confirmPin : _pin;
    return AlertDialog(
      title: Text(_confirming ? 'PIN 확인' : 'PIN 설정'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _confirming ? 'PIN을 다시 입력해 주세요.' : '사용할 PIN 6자리를 입력해 주세요.',
            textAlign: TextAlign.center,
          ),
          if (_mismatch) ...[
            const SizedBox(height: 8),
            const Text(
              'PIN이 일치하지 않습니다.',
              style: TextStyle(color: Colors.red),
            ),
          ],
          const SizedBox(height: 16),
          PinDots(length: displayPin.length),
          const SizedBox(height: 16),
          if (_saving)
            const CircularProgressIndicator()
          else
            NumericPinPad(
              onDigitPressed: _onKey,
              onBackspacePressed: _onDelete,
            ),
        ],
      ),
    );
  }
}

class _RecoveryCodeDisplayDialog extends StatefulWidget {
  final String code;
  const _RecoveryCodeDisplayDialog({required this.code});

  @override
  State<_RecoveryCodeDisplayDialog> createState() =>
      _RecoveryCodeDisplayDialogState();
}

class _RecoveryCodeDisplayDialogState
    extends State<_RecoveryCodeDisplayDialog> {
  late String _displayCode;

  @override
  void initState() {
    super.initState();
    _displayCode = widget.code;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('복구 코드 저장'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '아래 복구 코드를 안전한 곳에 저장하세요.\nPIN을 잊었을 때 사용할 수 있으며 다시 표시되지 않습니다.',
          ),
          const SizedBox(height: 16),
          Text(
            _displayCode,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            setState(() => _displayCode = '');
            Navigator.of(context).pop();
          },
          child: const Text('저장했습니다'),
        ),
      ],
    );
  }
}

String _formatAmount(int amount, {bool isEnglish = false}) {
  return NumberFormat.decimalPattern(isEnglish ? 'en' : 'ko').format(amount);
}
