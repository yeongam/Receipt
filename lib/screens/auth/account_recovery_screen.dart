import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_preferences_format.dart';
import '../../providers/auth_provider.dart';

class AccountRecoveryScreen extends StatelessWidget {
  const AccountRecoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(context.tr('아이디 / 비밀번호 찾기', 'Find ID / Password')),
          bottom: TabBar(
            tabs: [
              Tab(text: context.tr('아이디 찾기', 'Find ID')),
              Tab(text: context.tr('비밀번호 재설정', 'Reset Password')),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _FindIdTab(),
            _ResetPasswordTab(),
          ],
        ),
      ),
    );
  }
}

// ─── Find ID Tab ──────────────────────────────────────────────────────────────

class _FindIdTab extends StatefulWidget {
  const _FindIdTab();

  @override
  State<_FindIdTab> createState() => _FindIdTabState();
}

class _FindIdTabState extends State<_FindIdTab> {
  final _nameController = TextEditingController();
  final _recoveryKeywordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _recoveryKeywordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final name = _nameController.text.trim();
    final recoveryKeyword = _recoveryKeywordController.text.trim();
    if (name.isEmpty || recoveryKeyword.isEmpty) {
      _showMessage(isEnglish
          ? 'Please enter both your name and recovery keyword.'
          : '이름과 복구 키워드를 모두 입력해 주세요.');
      return;
    }

    final username =
        await context.read<AuthProvider>().findUsernameByRecovery(
              name: name,
              recoveryKeyword: recoveryKeyword,
            );

    if (!mounted) return;
    if (username == null || username.isEmpty) {
      _showMessage(isEnglish
          ? 'We could not verify your recovery information.'
          : '복구 정보를 확인하지 못했어요.');
      return;
    }
    _showMessage(isEnglish
        ? 'Your registered ID is $username.'
        : '가입된 아이디는 $username예요.');
  }

  @override
  Widget build(BuildContext context) {
    final secondaryTextColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.68);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.person_search_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              context.tr('아이디 찾기', 'Find ID'),
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              context.tr(
                '가입 시 등록한 이름과 복구 키워드를 입력하세요.',
                'Enter the name and recovery keyword you registered with.',
              ),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: secondaryTextColor,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            context.tr('이름', 'Name'),
            style: AppTextStyles.labelLarge.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _RecoveryTextField(
            controller: _nameController,
            hintText: context.tr('이름을 입력하세요', 'Enter your name'),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('복구 키워드', 'Recovery Keyword'),
            style: AppTextStyles.labelLarge.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _RecoveryTextField(
            controller: _recoveryKeywordController,
            hintText: context.tr(
              '가입 시 입력한 복구 답변을 입력하세요',
              'Enter the recovery answer you used at sign-up',
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: AppTextStyles.titleMedium.copyWith(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: Text(context.tr('아이디 찾기', 'Find ID')),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reset Password Tab ───────────────────────────────────────────────────────

class _ResetPasswordTab extends StatefulWidget {
  const _ResetPasswordTab();

  @override
  State<_ResetPasswordTab> createState() => _ResetPasswordTabState();
}

class _ResetPasswordTabState extends State<_ResetPasswordTab> {
  final _idController = TextEditingController();
  final _recoveryCodeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isVerified = false;
  bool _isResetting = false;
  String _verifiedUserId = '';
  String _pendingRecoveryCode = '';

  @override
  void dispose() {
    _idController.dispose();
    _recoveryCodeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final userId = _idController.text.trim();
    final recoveryCode = _recoveryCodeController.text.trim();
    if (userId.isEmpty || recoveryCode.isEmpty) {
      _showMessage(isEnglish
          ? 'Please enter your ID and recovery code.'
          : '아이디와 복구 코드를 모두 입력해 주세요.');
      return;
    }
    setState(() {
      _isVerified = true;
      _verifiedUserId = userId;
      _pendingRecoveryCode = recoveryCode;
    });
    _showMessage(isEnglish
        ? 'Identity verification is complete. Enter a new password.'
        : '본인 확인이 완료됐어요. 새 비밀번호를 입력해 주세요.');
  }

  Future<void> _resetPassword() async {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      _showMessage(isEnglish
          ? 'Please enter and confirm your new password.'
          : '새 비밀번호와 확인 비밀번호를 모두 입력해 주세요.');
      return;
    }
    if (newPassword != confirmPassword) {
      _showMessage(isEnglish
          ? 'The new password and confirmation do not match.'
          : '새 비밀번호와 확인 비밀번호가 일치하지 않아요.');
      return;
    }
    if (newPassword.length < 6) {
      _showMessage(isEnglish
          ? 'Password must be at least 6 characters.'
          : '비밀번호는 6자 이상이어야 해요.');
      return;
    }

    setState(() => _isResetting = true);
    final ok =
        await context.read<AuthProvider>().resetPasswordWithRecovery(
              username: _verifiedUserId,
              recoveryCode: _pendingRecoveryCode,
              newPassword: newPassword,
            );
    if (!mounted) return;
    setState(() => _isResetting = false);

    if (ok) {
      _showMessage(isEnglish
          ? 'Your password has been changed. Please log in again.'
          : '비밀번호를 변경했어요. 다시 로그인해 주세요.');
      Navigator.of(context).pop();
    } else {
      _showMessage(isEnglish
          ? 'Password reset failed. Please check your recovery code.'
          : '비밀번호 재설정에 실패했어요. 복구 코드를 확인해 주세요.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final secondaryTextColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.68);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.lock_reset_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              context.tr('비밀번호 재설정', 'Reset Password'),
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              context.tr(
                '아이디와 복구 코드로 본인을 확인한 후 새 비밀번호를 설정하세요.',
                'Verify your identity with your ID and recovery code, then set a new password.',
              ),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: secondaryTextColor,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 28),
          if (!_isVerified) ...[
            Text(
              context.tr('아이디', 'ID'),
              style: AppTextStyles.labelLarge.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            _RecoveryTextField(
              controller: _idController,
              hintText: context.tr('아이디를 입력하세요', 'Enter your ID'),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('복구 코드', 'Recovery Code'),
              style: AppTextStyles.labelLarge.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            _RecoveryTextField(
              controller: _recoveryCodeController,
              hintText: context.tr(
                '가입 시 설정한 복구 코드를 입력하세요',
                'Enter the recovery code you set at sign-up',
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: AppTextStyles.titleMedium.copyWith(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: Text(context.tr('본인 확인', 'Verify Identity')),
              ),
            ),
          ] else ...[
            Text(
              context.tr('새 비밀번호', 'New Password'),
              style: AppTextStyles.labelLarge.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            _RecoveryTextField(
              controller: _newPasswordController,
              hintText: context.tr(
                '새 비밀번호를 입력하세요',
                'Enter your new password',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('새 비밀번호 확인', 'Confirm New Password'),
              style: AppTextStyles.labelLarge.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            _RecoveryTextField(
              controller: _confirmPasswordController,
              hintText: context.tr(
                '새 비밀번호를 다시 입력하세요',
                'Enter your new password again',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isResetting ? null : _resetPassword,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: AppTextStyles.titleMedium.copyWith(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: _isResetting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(context.tr('비밀번호 변경', 'Change Password')),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Shared TextField ─────────────────────────────────────────────────────────

class _RecoveryTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final bool obscureText;

  const _RecoveryTextField({
    this.controller,
    required this.hintText,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: AppTextStyles.bodyMedium.copyWith(
        fontSize: 15,
        color: Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          fontSize: 15,
          color: Theme.of(context).hintColor,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
  }
}
