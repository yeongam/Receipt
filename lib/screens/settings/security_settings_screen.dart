import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';
import '../shared/pin_pad.dart';
import 'settings_widgets.dart';

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
        SwitchCard(
          title: '앱 실행 잠금',
          subtitle: '앱을 열 때 비밀번호나 생체 인증을 사용해요.',
          value: settings.lockOnLaunch,
          onChanged: _onLockOnLaunchChanged,
        ),
        SwitchCard(
          title: '생체 인증 사용',
          subtitle: 'Face ID 또는 지문 인증을 사용해요.',
          value: settings.biometric,
          onChanged: _onBiometricChanged,
        ),
      ],
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
