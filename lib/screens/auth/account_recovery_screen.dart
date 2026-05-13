import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_preferences_format.dart';

class AccountRecoveryScreen extends StatelessWidget {
  const AccountRecoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(context.tr('계정 복구', 'Account Recovery')),
      ),
      body: const _RecoveryForm(),
    );
  }
}

/// Two-phase form:
/// Phase 1 — verify identity (username + recovery code).
/// Phase 2 — set new password (shown after verification succeeds).
class _RecoveryForm extends StatefulWidget {
  const _RecoveryForm();

  @override
  State<_RecoveryForm> createState() => _RecoveryFormState();
}

class _RecoveryFormState extends State<_RecoveryForm> {
  // Phase 1
  final _idCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _obscureCode = true;

  // Phase 2
  final _pwCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePw = true;
  bool _obscureConfirm = true;

  bool _isLoading = false;
  bool _codeEntered = false;
  String? _errorText;

  static const int _maxAttempts = 5;
  int _attempts = 0;

  @override
  void dispose() {
    _idCtrl.dispose();
    _codeCtrl.dispose();
    _pwCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  /// Phase 1: just validate fields are non-empty, then show Phase 2.
  void _proceedToNewPassword() {
    if (_idCtrl.text.trim().isEmpty || _codeCtrl.text.trim().isEmpty) return;
    setState(() {
      _codeEntered = true;
      _errorText = null;
    });
  }

  /// Phase 2: call Edge Function with username + recovery code + new password.
  Future<void> _resetPassword() async {
    if (_attempts >= _maxAttempts) return;
    final password = _pwCtrl.text;
    final confirm = _confirmCtrl.text;

    if (password.isEmpty) return;
    if (password != confirm) {
      setState(() => _errorText =
          context.tr('비밀번호가 일치하지 않습니다.', 'Passwords do not match.'));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'reset-password-with-recovery-code',
        body: {
          'username': _idCtrl.text.trim(),
          'recoveryCode': _codeCtrl.text.trim(),
          'newPassword': password,
        },
      );

      if (!mounted) return;

      final data = response.data as Map<String, dynamic>?;
      if (data?['success'] == true) {
        _showSuccess();
      } else {
        _attempts++;
        final err = data?['error'] as String? ?? 'unknown';
        setState(() {
          _errorText = switch (err) {
            'invalid_credentials' => _attempts >= _maxAttempts
                ? context.tr('시도 횟수를 초과했습니다.', 'Too many attempts.')
                : context.tr(
                    '아이디 또는 복구 코드가 올바르지 않습니다.',
                    'Invalid ID or recovery code.',
                  ),
            'password_too_short' =>
              context.tr('비밀번호는 6자 이상이어야 합니다.', 'Password must be at least 6 characters.'),
            _ => context.tr('오류가 발생했습니다.', 'An error occurred.'),
          };
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorText = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccess() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(context.tr('완료', 'Done')),
        content: Text(context.tr(
          '비밀번호가 재설정되었습니다.\n다시 로그인해 주세요.',
          'Password has been reset.\nPlease log in again.',
        )),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text(context.tr('로그인으로', 'Go to login')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        _Header(verified: _codeEntered),
        const SizedBox(height: 24),
        if (!_codeEntered) _phase1() else _phase2(),
      ],
    );
  }

  Widget _phase1() {
    final exhausted = _attempts >= _maxAttempts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr('아이디', 'Username'),
            style:
                AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        _RecoveryTextField(
          controller: _idCtrl,
          hintText: context.tr('아이디를 입력하세요', 'Enter your username'),
          enabled: !exhausted,
          onChanged: (_) => setState(() => _errorText = null),
        ),
        const SizedBox(height: 20),
        Text(context.tr('복구 코드', 'Recovery Code'),
            style:
                AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        _RecoveryTextField(
          controller: _codeCtrl,
          hintText: context.tr('복구 코드를 입력하세요', 'Enter your recovery code'),
          obscureText: _obscureCode,
          enabled: !exhausted,
          errorText: _errorText,
          onChanged: (_) => setState(() => _errorText = null),
          suffixIcon: IconButton(
            icon: Icon(
                _obscureCode ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _obscureCode = !_obscureCode),
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: exhausted ? null : _proceedToNewPassword,
            child: Text(context.tr('다음', 'Next')),
          ),
        ),
      ],
    );
  }

  Widget _phase2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr('새 비밀번호', 'New Password'),
            style:
                AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        _RecoveryTextField(
          controller: _pwCtrl,
          hintText: context.tr('새 비밀번호를 입력하세요', 'Enter new password'),
          obscureText: _obscurePw,
          onChanged: (_) => setState(() => _errorText = null),
          suffixIcon: IconButton(
            icon: Icon(_obscurePw ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _obscurePw = !_obscurePw),
          ),
        ),
        const SizedBox(height: 20),
        Text(context.tr('비밀번호 확인', 'Confirm Password'),
            style:
                AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        _RecoveryTextField(
          controller: _confirmCtrl,
          hintText: context.tr('비밀번호를 다시 입력하세요', 'Re-enter password'),
          obscureText: _obscureConfirm,
          errorText: _errorText,
          onChanged: (_) => setState(() => _errorText = null),
          suffixIcon: IconButton(
            icon: Icon(
                _obscureConfirm ? Icons.visibility_off : Icons.visibility),
            onPressed: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _resetPassword,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(context.tr('비밀번호 재설정', 'Reset Password')),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final bool verified;
  const _Header({required this.verified});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              verified ? Icons.lock_open_rounded : Icons.lock_reset_rounded,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(
                    verified ? '복구 코드 확인 완료' : '비밀번호 재설정',
                    verified ? 'Identity Verified' : 'Reset Password',
                  ),
                  style: AppTextStyles.titleLarge
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr(
                    verified
                        ? '새 비밀번호를 설정해 주세요.'
                        : '아이디와 복구 코드를 입력하세요.',
                    verified
                        ? 'Set your new password below.'
                        : 'Enter your username and recovery code.',
                  ),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.68),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecoveryTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final bool enabled;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final Widget? suffixIcon;

  const _RecoveryTextField({
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.enabled = true,
    this.errorText,
    this.onChanged,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        errorText: errorText,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
