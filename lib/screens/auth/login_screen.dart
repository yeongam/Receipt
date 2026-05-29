import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_preferences_format.dart';
import '../../providers/auth_provider.dart';
import '../shared/edge_overscroll_background.dart';
import 'account_recovery_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;
  final VoidCallback onSignup;

  const LoginScreen({
    super.key,
    required this.onLogin,
    required this.onSignup,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final secondaryTextColor = onSurfaceColor.withValues(alpha: 0.68);
    final authScale = _authScale(context);

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: EdgeOverscrollBackground(
        topColor: AppColors.primary,
        bottomColor: surfaceColor,
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        color: AppColors.primary,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(28, 26, 28, 30),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Align(
                                alignment: Alignment.topRight,
                                child: Text(
                                  context.tr('로그인', 'Login'),
                                  style: AppTextStyles.labelMedium.copyWith(
                                    fontSize: 13 * authScale,
                                    color: Colors.white.withValues(alpha: 0.78),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.22),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 30),
                              Text(
                                '내돈내역',
                                style: AppTextStyles.displayMedium.copyWith(
                                  fontSize: 31 * authScale,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  height: 1.12,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                context.tr('가계부를 시작해보세요', 'Start your ledger'),
                                style: AppTextStyles.titleMedium.copyWith(
                                  fontSize: 17 * authScale,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                context.tr(
                                  '직접 입력한 입금과 출금을 기준으로\n하루 소비를 간결하게 기록할 수 있어요.',
                                  'Track your day clearly\nwith the income and expenses you enter yourself.',
                                ),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontSize: 15 * authScale,
                                  color: Colors.white.withValues(alpha: 0.74),
                                  height: 1.6,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(32)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 30, 24, 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('로그인', 'Login'),
                                style: AppTextStyles.headlineSmall.copyWith(
                                  fontSize: 20 * authScale,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                context.tr(
                                  '아이디와 비밀번호를 입력해 주세요',
                                  'Enter your ID and password',
                                ),
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontSize: 13 * authScale,
                                  color: secondaryTextColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 24),
                              _AuthFieldLabel(context.tr('아이디', 'ID')),
                              const SizedBox(height: 8),
                              _AuthTextField(
                                controller: _idController,
                                hintText:
                                    context.tr('아이디를 입력하세요', 'Enter your ID'),
                              ),
                              const SizedBox(height: 18),
                              _AuthFieldLabel(context.tr('비밀번호', 'Password')),
                              const SizedBox(height: 8),
                              _AuthTextField(
                                controller: _passwordController,
                                hintText: context.tr(
                                    '비밀번호를 입력하세요', 'Enter your password'),
                                obscureText: true,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) =>
                                              const AccountRecoveryScreen(),
                                        ),
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(0, 0),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      context.tr(
                                          '아이디/비밀번호 찾기', 'Find ID / Password'),
                                      style: AppTextStyles.caption.copyWith(
                                        fontSize: 12 * authScale,
                                        color: secondaryTextColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final auth =
                                        context.read<AuthProvider>();
                                    final defaultErrorMsg = context.tr(
                                      '아이디 또는 비밀번호가 일치하지 않아요.',
                                      'The ID or password does not match.',
                                    );
                                    final success = await auth.signIn(
                                      username: _idController.text.trim(),
                                      password: _passwordController.text.trim(),
                                    );
                                    if (!mounted) return;
                                    if (!success) {
                                      _showMessage(
                                        auth.errorMessage ?? defaultErrorMsg,
                                      );
                                      return;
                                    }
                                    widget.onLogin();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    textStyle:
                                        AppTextStyles.titleMedium.copyWith(
                                      fontSize: 16 * authScale,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  child: Text(context.tr('로그인', 'Login')),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    context.tr(
                                        '회원이 아니신가요?', 'Not a member yet?'),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      fontSize: 13 * authScale,
                                      color: secondaryTextColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: widget.onSignup,
                                    child: Text(
                                      context.tr('회원가입', 'Sign up'),
                                      style: AppTextStyles.bodySmall.copyWith(
                                        fontSize: 13 * authScale,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  double _authScale(BuildContext context) {
    return 1.0;
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _AuthFieldLabel extends StatelessWidget {
  final String label;

  const _AuthFieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.labelLarge.copyWith(
        fontSize: 15,
        color: Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final bool obscureText;

  const _AuthTextField({
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
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
  }
}
