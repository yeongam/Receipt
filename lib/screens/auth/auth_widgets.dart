import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show TextInputFormatter;

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class AuthFieldLabel extends StatelessWidget {
  final String label;
  const AuthFieldLabel(this.label, {super.key});

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

class AuthTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final bool obscureText;
  final List<TextInputFormatter>? inputFormatters;

  const AuthTextField({
    super.key,
    this.controller,
    required this.hintText,
    this.obscureText = false,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      inputFormatters: inputFormatters,
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
