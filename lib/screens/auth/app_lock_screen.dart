import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../shared/pin_pad.dart';

class AppLockScreen extends StatefulWidget {
  final Future<bool> Function(String pin) validatePin;
  final Future<bool> Function(String code) validateRecoveryCode;
  final Future<void> Function() disableAppLock;
  final VoidCallback onUnlocked;
  final bool biometricEnabled;

  const AppLockScreen({
    super.key,
    required this.validatePin,
    required this.validateRecoveryCode,
    required this.disableAppLock,
    required this.onUnlocked,
    this.biometricEnabled = false,
  });

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  static const _storage = FlutterSecureStorage();
  static const _attemptsKey = 'app_lock_failed_attempts';

  String _pin = '';
  int _failedAttempts = 0;
  static const int _maxAttempts = 5;
  bool _showError = false;
  bool _validating = false;
  bool _biometricTriggered = false;

  @override
  void initState() {
    super.initState();
    _storage.read(key: _attemptsKey).then((stored) {
      if (stored != null && mounted) {
        setState(() => _failedAttempts = int.tryParse(stored) ?? 0);
      }
    });
    if (widget.biometricEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
    }
  }

  Future<void> _tryBiometric() async {
    if (_biometricTriggered) return;
    _biometricTriggered = true;
    try {
      final auth = LocalAuthentication();
      final canCheck = await auth.canCheckBiometrics;
      if (!canCheck || !mounted) {
        _biometricTriggered = false;
        return;
      }
      final authenticated = await auth.authenticate(
        localizedReason: '생체 인증으로 잠금을 해제하세요',
        options: const AuthenticationOptions(stickyAuth: true),
      );
      if (authenticated && mounted) {
        await _storage.delete(key: _attemptsKey);
        if (mounted) widget.onUnlocked();
      } else {
        _biometricTriggered = false;
      }
    } catch (_) {
      _biometricTriggered = false;
    }
  }

  void _onKey(String digit) {
    if (_pin.length >= 6 || _validating) return;
    setState(() {
      _pin += digit;
      _showError = false;
    });
    if (_pin.length == 6) _submit();
  }

  void _onDelete() {
    if (_pin.isEmpty || _validating) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _submit() async {
    if (_validating) return;
    final pin = _pin;
    setState(() {
      _validating = true;
      _pin = '';
    });
    final ok = await widget.validatePin(pin);
    if (!mounted) return;
    setState(() => _validating = false);
    if (ok) {
      await _storage.delete(key: _attemptsKey);
      if (mounted) widget.onUnlocked();
    } else {
      setState(() {
        _failedAttempts++;
        _showError = true;
      });
      await _storage.write(key: _attemptsKey, value: '$_failedAttempts');
      if (_failedAttempts >= _maxAttempts) {
        _showRecoveryDialog();
      }
    }
  }

  void _showRecoveryDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RecoveryCodeUnlockDialog(
        validateCode: widget.validateRecoveryCode,
        disableLock: widget.disableAppLock,
        onUnlocked: widget.onUnlocked,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : theme.colorScheme.surface;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.secondary;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            const Icon(
              Icons.lock_outline_rounded,
              size: 48,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'PIN 입력',
              style: AppTextStyles.displayLarge.copyWith(
                color: textColor,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (_showError)
              Text(
                _failedAttempts >= _maxAttempts
                    ? '시도 횟수 초과'
                    : '잘못된 PIN입니다 ($_failedAttempts/$_maxAttempts)',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.expense,
                ),
              )
            else
              const SizedBox(height: 18),
            const SizedBox(height: 24),
            PinDots(length: _pin.length),
            const SizedBox(height: 32),
            if (_validating)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(),
              )
            else
              NumericPinPad(
                onDigitPressed: _onKey,
                onBackspacePressed: _onDelete,
              ),
            const SizedBox(height: 24),
            if (widget.biometricEnabled) ...[
              TextButton.icon(
                onPressed: _validating ? null : _tryBiometric,
                icon: const Icon(Icons.fingerprint),
                label: const Text('생체 인증으로 해제'),
              ),
              const SizedBox(height: 4),
            ],
            if (_failedAttempts >= 3)
              TextButton(
                onPressed: _validating ? null : _showRecoveryDialog,
                child: Text(
                'PIN을 잊으셨나요?',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class RecoveryCodeUnlockDialog extends StatefulWidget {
  final Future<bool> Function(String code) validateCode;
  final Future<void> Function() disableLock;
  final VoidCallback onUnlocked;

  const RecoveryCodeUnlockDialog({
    super.key,
    required this.validateCode,
    required this.disableLock,
    required this.onUnlocked,
  });

  @override
  State<RecoveryCodeUnlockDialog> createState() =>
      _RecoveryCodeUnlockDialogState();
}

class _RecoveryCodeUnlockDialogState extends State<RecoveryCodeUnlockDialog> {
  final _controller = TextEditingController();
  bool _showError = false;
  bool _obscureCode = true;
  int _attempts = 0;
  static const int _maxAttempts = 5;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_attempts >= _maxAttempts) return;
    final ok = await widget.validateCode(_controller.text.trim());
    if (!mounted) return;
    if (ok) {
      await widget.disableLock();
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onUnlocked();
    } else {
      setState(() {
        _showError = true;
        _attempts++;
      });
      if (_attempts >= _maxAttempts && mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final exhausted = _attempts >= _maxAttempts;
    return AlertDialog(
      title: const Text('복구 코드로 잠금 해제'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('앱잠금 설정 시 발급된 복구 코드를 입력하세요.'),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            enabled: !exhausted,
            obscureText: _obscureCode,
            decoration: InputDecoration(
              labelText: '복구 코드',
              errorText: _showError ? '올바르지 않은 복구 코드입니다.' : null,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureCode ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => _obscureCode = !_obscureCode),
              ),
            ),
            onChanged: (_) => setState(() => _showError = false),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: exhausted ? null : _submit,
          child: const Text('확인'),
        ),
      ],
    );
  }
}
