import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';

class SignupScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onBackToLogin;

  const SignupScreen({
    super.key,
    required this.onComplete,
    required this.onBackToLogin,
  });

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _agreeAge = false;
  bool _agreePrivacy = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('모든 항목을 입력해주세요')));
      return;
    }
    if (password != confirm) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('비밀번호가 일치하지 않습니다')));
      return;
    }
    if (!_agreeAge || !_agreePrivacy) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('필수 약관에 동의해주세요')));
      return;
    }

    setState(() => _isLoading = true);
    final ok = await context.read<AuthProvider>().signUp(
          email: email,
          password: password,
          name: name,
        );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      widget.onComplete();
    } else {
      final err = context.read<AuthProvider>().errorMessage ?? '회원가입 실패';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '어플 이름 및 로고',
                      style: AppTextStyles.headlineMedium
                          .copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '가계부 회원을 등록하세요',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: Colors.white.withAlpha(220)),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 7,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('이름', style: AppTextStyles.labelMedium),
                      const SizedBox(height: 8),
                      _SignupTextField(
                        controller: _nameCtrl,
                        hintText: '이름을 입력하세요',
                      ),
                      const SizedBox(height: 14),
                      const Text('이메일', style: AppTextStyles.labelMedium),
                      const SizedBox(height: 8),
                      _SignupTextField(
                        controller: _emailCtrl,
                        hintText: '이메일을 입력하세요',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      const Text('비밀번호', style: AppTextStyles.labelMedium),
                      const SizedBox(height: 8),
                      _SignupTextField(
                        controller: _passwordCtrl,
                        hintText: '비밀번호를 입력하세요',
                        obscureText: true,
                      ),
                      const SizedBox(height: 14),
                      const Text('비밀번호 확인', style: AppTextStyles.labelMedium),
                      const SizedBox(height: 8),
                      _SignupTextField(
                        controller: _confirmCtrl,
                        hintText: '비밀번호를 다시 입력하세요',
                        obscureText: true,
                      ),
                      const SizedBox(height: 18),
                      CheckboxListTile(
                        value: _agreeAge,
                        onChanged: (value) {
                          setState(() => _agreeAge = value ?? false);
                        },
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text(
                          '만 14세 이상입니다',
                          style: AppTextStyles.bodySmall,
                        ),
                      ),
                      CheckboxListTile(
                        value: _agreePrivacy,
                        onChanged: (value) {
                          setState(() => _agreePrivacy = value ?? false);
                        },
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text(
                          '개인정보 수집 및 서비스 이용에 동의합니다',
                          style: AppTextStyles.bodySmall,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('회원가입'),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '이미 계정이 있으신가요?',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textSecondary),
                          ),
                          TextButton(
                            onPressed: widget.onBackToLogin,
                            child: Text(
                              '로그인',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignupTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType keyboardType;

  const _SignupTextField({
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}
