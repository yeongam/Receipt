import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class PinDots extends StatelessWidget {
  const PinDots({
    super.key,
    required this.length,
  });

  final int length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          6,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: index < length ? 18 : 14,
            height: index < length ? 18 : 14,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: index < length
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
              border: Border.all(
                color: index < length
                    ? theme.colorScheme.primary
                    : theme.dividerColor.withValues(alpha: 0.55),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NumericPinPad extends StatelessWidget {
  const NumericPinPad({
    super.key,
    required this.onDigitPressed,
    required this.onBackspacePressed,
  });

  final ValueChanged<String> onDigitPressed;
  final VoidCallback onBackspacePressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Column(
        children: [
          _PinPadRow(digits: ['1', '2', '3']),
          SizedBox(height: 10),
          _PinPadRow(digits: ['4', '5', '6']),
          SizedBox(height: 10),
          _PinPadRow(digits: ['7', '8', '9']),
          SizedBox(height: 10),
          _PinPadLastRow(),
        ],
      ),
    );
  }
}

class _PinPadRow extends StatelessWidget {
  const _PinPadRow({
    required this.digits,
  });

  final List<String> digits;

  @override
  Widget build(BuildContext context) {
    final pad = context.findAncestorWidgetOfExactType<NumericPinPad>()!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: digits
          .map(
            (digit) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _PinKey(
                label: digit,
                onPressed: () => pad.onDigitPressed(digit),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _PinPadLastRow extends StatelessWidget {
  const _PinPadLastRow();

  @override
  Widget build(BuildContext context) {
    final pad = context.findAncestorWidgetOfExactType<NumericPinPad>()!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(width: 84),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _PinKey(
            label: '0',
            onPressed: () => pad.onDigitPressed('0'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _PinKey(
            icon: Icons.backspace_outlined,
            onPressed: pad.onBackspacePressed,
          ),
        ),
      ],
    );
  }
}

class _PinKey extends StatefulWidget {
  const _PinKey({
    this.label,
    this.icon,
    required this.onPressed,
  });

  final String? label;
  final IconData? icon;
  final VoidCallback onPressed;

  @override
  State<_PinKey> createState() => _PinKeyState();
}

class _PinKeyState extends State<_PinKey> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOutCubic,
            width: 70,
            height: 58,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest.withValues(
                alpha: _pressed ? 0.9 : 0.68,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _pressed
                    ? theme.colorScheme.primary.withValues(alpha: 0.32)
                    : theme.dividerColor.withValues(alpha: 0.18),
              ),
            ),
            child: Center(
              child: widget.label != null
                  ? Text(
                      widget.label!,
                      style: AppTextStyles.titleLarge.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.icon,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
