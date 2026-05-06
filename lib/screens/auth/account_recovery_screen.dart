import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_preferences_format.dart';

class AccountRecoveryScreen extends StatelessWidget {
  const AccountRecoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 1,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(context.tr('비밀번호 재설정', 'Reset Password')),
        ),
        body: const _ResetPasswordTab(),
      ),
    );
  }
}

class _ResetPasswordTab extends StatefulWidget {
  const _ResetPasswordTab();

  @override
  State<_ResetPasswordTab> createState() => _ResetPasswordTabState();
}

class _ResetPasswordTabState extends State<_ResetPasswordTab> {
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (!mounted) return;
      setState(() => _sent = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_sent) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.accentLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_rounded,
                  color: AppColors.accent,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                context.tr('이메일을 확인하세요', 'Check your email'),
                style: AppTextStyles.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                context.tr(
                  '비밀번호 재설정 링크를 이메일로 보냈어요.\n메일함을 확인해 주세요.',
                  'We sent a password reset link to your email.\nPlease check your inbox.',
                ),
                style: AppTextStyles.bodySmall.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.68),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(context.tr('로그인으로 돌아가기', 'Back to login')),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.lock_reset_rounded,
                    color: AppColors.primary, size: 26),
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('비밀번호 재설정', 'Reset Password'),
                style: AppTextStyles.titleLarge
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr(
                  '가입한 이메일을 입력하면 재설정 링크를 보내드려요.',
                  'Enter your registered email and we\'ll send a reset link.',
                ),
                style: AppTextStyles.bodySmall.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.68),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                context.tr('이메일', 'Email'),
                style: AppTextStyles.labelMedium
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: context.tr('이메일을 입력하세요', 'Enter your email'),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(context.tr('재설정 링크 보내기', 'Send reset link')),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
