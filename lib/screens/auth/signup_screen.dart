import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_preferences_format.dart';
import '../../providers/auth_provider.dart';
import '../shared/edge_overscroll_background.dart';

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
  bool _agreeTerms = false;
  bool _agreePrivacy = false;
  bool _agreeRecovery = false;
  bool _agreeMarketing = false;
  bool _agreeUpdates = false;
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool get _allAgreementsChecked =>
      _agreeTerms &&
      _agreePrivacy &&
      _agreeRecovery &&
      _agreeMarketing &&
      _agreeUpdates;

  bool get _hasRequiredAgreements =>
      _agreeTerms && _agreePrivacy && _agreeRecovery;

  void _setAllAgreements(bool value) {
    setState(() {
      _agreeTerms = value;
      _agreePrivacy = value;
      _agreeRecovery = value;
      _agreeMarketing = value;
      _agreeUpdates = value;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final secondaryTextColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.68);
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
                                  context.tr('회원가입', 'Sign up'),
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
                                  Icons.person_add_alt_1_rounded,
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
                                context.tr('가계부 회원을 등록하세요',
                                    'Create your ledger account'),
                                style: AppTextStyles.titleMedium.copyWith(
                                  fontSize: 17 * authScale,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                context.tr(
                                  '매일의 입출금을 차곡차곡 쌓아\n나만의 소비 흐름을 확인할 수 있어요.',
                                  'Build your daily entries over time\nand see your own spending pattern.',
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
                                context.tr('회원가입', 'Sign up'),
                                style: AppTextStyles.headlineSmall.copyWith(
                                  fontSize: 20 * authScale,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                context.tr(
                                  '기본 정보를 입력해 계정을 만들어 주세요',
                                  'Enter your basic details to create an account',
                                ),
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontSize: 13 * authScale,
                                  color: secondaryTextColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 24),
                              _SignupFieldLabel(context.tr('이름', 'Name')),
                              const SizedBox(height: 8),
                              _SignupTextField(
                                controller: _nameController,
                                hintText:
                                    context.tr('이름을 입력하세요', 'Enter your name'),
                              ),
                              const SizedBox(height: 16),
                              _SignupFieldLabel(context.tr('아이디', 'ID')),
                              const SizedBox(height: 8),
                              _SignupTextField(
                                controller: _idController,
                                hintText:
                                    context.tr('아이디를 입력하세요', 'Enter your ID'),
                              ),
                              const SizedBox(height: 16),
                              _SignupFieldLabel(context.tr('비밀번호', 'Password')),
                              const SizedBox(height: 8),
                              _SignupTextField(
                                controller: _passwordController,
                                hintText: context.tr(
                                    '비밀번호를 입력하세요', 'Enter your password'),
                                obscureText: true,
                              ),
                              const SizedBox(height: 16),
                              _SignupFieldLabel(
                                  context.tr('비밀번호 확인', 'Confirm password')),
                              const SizedBox(height: 8),
                              _SignupTextField(
                                controller: _confirmPasswordController,
                                hintText: context.tr(
                                  '비밀번호를 다시 입력하세요',
                                  'Enter your password again',
                                ),
                                obscureText: true,
                              ),
                              const SizedBox(height: 24),
                              _AgreementSection(
                                allChecked: _allAgreementsChecked,
                                secondaryTextColor: secondaryTextColor,
                                onToggleAll: _setAllAgreements,
                                children: [
                                  _AgreementRow(
                                    value: _agreeTerms,
                                    label: context.tr(
                                      '서비스 이용약관에 동의합니다.',
                                      'I agree to the Terms of Service.',
                                    ),
                                    badge: context.tr('필수', 'Required'),
                                    onChanged: (value) {
                                      setState(
                                          () => _agreeTerms = value ?? false);
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  _AgreementRow(
                                    value: _agreePrivacy,
                                    label: context.tr(
                                      '개인정보 수집 및 이용에 동의합니다.',
                                      'I agree to the Privacy Policy.',
                                    ),
                                    badge: context.tr('필수', 'Required'),
                                    onChanged: (value) {
                                      setState(
                                          () => _agreePrivacy = value ?? false);
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  _AgreementRow(
                                    value: _agreeRecovery,
                                    label: context.tr(
                                      '서비스 이용 및 개인정보 처리에 관한 약관에 동의합니다.',
                                      'I agree to the terms regarding service use and personal data processing.',
                                    ),
                                    badge: context.tr('필수', 'Required'),
                                    onChanged: (value) {
                                      setState(() =>
                                          _agreeRecovery = value ?? false);
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  _AgreementDivider(
                                      label: context.tr('선택 약관', 'Optional')),
                                  const SizedBox(height: 14),
                                  _AgreementRow(
                                    value: _agreeMarketing,
                                    label: context.tr(
                                      '이벤트 및 혜택 안내 알림을 받겠습니다.',
                                      'I want to receive event and benefit notices.',
                                    ),
                                    badge: context.tr('선택', 'Optional'),
                                    onChanged: (value) {
                                      setState(() =>
                                          _agreeMarketing = value ?? false);
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  _AgreementRow(
                                    value: _agreeUpdates,
                                    label: context.tr(
                                      '업데이트 및 새 기능 안내를 받겠습니다.',
                                      'I want to receive updates and feature news.',
                                    ),
                                    badge: context.tr('선택', 'Optional'),
                                    onChanged: (value) {
                                      setState(
                                          () => _agreeUpdates = value ?? false);
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final name = _nameController.text.trim();
                                    final userId = _idController.text.trim();
                                    final password =
                                        _passwordController.text.trim();
                                    final confirmPassword =
                                        _confirmPasswordController.text.trim();
                                    final isEnglish = context.isEnglish;

                                    if (name.isEmpty ||
                                        userId.isEmpty ||
                                        password.isEmpty ||
                                        confirmPassword.isEmpty) {
                                      _showMessage(
                                        isEnglish
                                            ? 'Please fill in all sign-up fields.'
                                            : '회원가입 항목을 모두 입력해 주세요.',
                                      );
                                      return;
                                    }

                                    if (password != confirmPassword) {
                                      _showMessage(
                                        isEnglish
                                            ? 'The password and confirmation do not match.'
                                            : '비밀번호와 확인 비밀번호가 일치하지 않아요.',
                                      );
                                      return;
                                    }

                                    if (!_hasRequiredAgreements) {
                                      _showMessage(
                                        isEnglish
                                            ? 'Please agree to the required terms.'
                                            : '필수 동의 항목을 확인해 주세요.',
                                      );
                                      return;
                                    }

                                    final auth = context.read<AuthProvider>();
                                    final success = await auth.signUp(
                                      username: userId,
                                      password: password,
                                    );
                                    if (!mounted) return;
                                    if (!success) {
                                      _showMessage(
                                        auth.errorMessage ??
                                            (isEnglish
                                                ? 'Sign-up failed. Please try again.'
                                                : '회원가입에 실패했어요. 다시 시도해 주세요.'),
                                      );
                                      return;
                                    }
                                    widget.onComplete();
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
                                  child: Text(context.tr('회원가입', 'Sign up')),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    context.tr('이미 계정이 있으신가요?',
                                        'Already have an account?'),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      fontSize: 13 * authScale,
                                      color: secondaryTextColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: widget.onBackToLogin,
                                    child: Text(
                                      context.tr('로그인', 'Login'),
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

class _SignupFieldLabel extends StatelessWidget {
  final String label;

  const _SignupFieldLabel(this.label);

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

class _SignupTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final bool obscureText;

  const _SignupTextField({
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

class _AgreementRow extends StatelessWidget {
  final bool value;
  final String label;
  final String badge;
  final ValueChanged<bool?> onChanged;

  const _AgreementRow({
    required this.value,
    required this.label,
    required this.badge,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value
              ? AppColors.primary.withValues(alpha: 0.22)
              : colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.scale(
            scale: 0.92,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badge == '필수' || badge == 'Required'
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: badge == '필수' || badge == 'Required'
                            ? AppColors.primary
                            : colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgreementSection extends StatelessWidget {
  final bool allChecked;
  final Color secondaryTextColor;
  final ValueChanged<bool> onToggleAll;
  final List<Widget> children;

  const _AgreementSection({
    required this.allChecked,
    required this.secondaryTextColor,
    required this.onToggleAll,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('약관 동의', 'Agreements'),
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr(
                        '모든 체크는 기본 해제되어 있어요. 필요한 항목을 직접 확인해 주세요.',
                        'All checkboxes are off by default. Please review and select them yourself.',
                      ),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: secondaryTextColor,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => onToggleAll(!allChecked),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: allChecked
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: allChecked
                          ? AppColors.primary.withValues(alpha: 0.24)
                          : colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    context.tr('모든 약관 동의', 'Agree to all'),
                    style: AppTextStyles.labelMedium.copyWith(
                      color: allChecked
                          ? AppColors.primary
                          : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _AgreementDivider extends StatelessWidget {
  final String label;

  const _AgreementDivider({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Divider(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            height: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            height: 1,
          ),
        ),
      ],
    );
  }
}
