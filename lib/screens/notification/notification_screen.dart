import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/signed_in_user_id.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_preferences_format.dart';
import '../../data/models/fixed_expense.dart';
import '../../providers/auth_provider.dart';
import '../../providers/fixed_expense_provider.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fixedExpenseProvider = context.watch<FixedExpenseProvider>();
    final items = fixedExpenseProvider.items;
    final enabledItems = fixedExpenseProvider.activeItems;
    final upcomingItem = items.where((e) => e.isActive).fold<FixedExpense?>(
      null,
      (prev, item) {
        if (prev == null) return item;
        return item.billingDay < prev.billingDay ? item : prev;
      },
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: Text(
          context.tr('고정 항목 관리', 'Recurring entries'),
          style: AppTextStyles.titleLarge.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _openExpenseEditor(context),
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('고정 입출금 자동 반영', 'Automatic recurring entries'),
                  style: AppTextStyles.sectionTitle,
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr(
                    '반복되는 지출과 입금을 등록해두면 매달 같은 흐름을 더 빠르게 관리할 수 있어요.',
                    'Register recurring expenses and income to manage the same monthly flow more quickly.',
                  ),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.68),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        label: context.tr('활성 항목', 'Active items'),
                        value: context.tr(
                          '${enabledItems.length}개',
                          '${enabledItems.length}',
                        ),
                        helper: context.tr(
                          '전체 ${items.length}개 등록',
                          '${items.length} total items',
                        ),
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        label: context.tr('활성 지출 합계', 'Active expense total'),
                        value: context.formatCurrency(
                          enabledItems.fold(0, (sum, e) => sum + e.amount),
                        ),
                        helper: context.tr(
                          '활성 ${enabledItems.length}건',
                          '${enabledItems.length} active',
                        ),
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkTextPrimary
                            : AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr('자동 반영 목록', 'Recurring entry list'),
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton(
                        onPressed: () => _openExpenseEditor(context),
                        child: Text(
                          context.tr('항목 추가', 'Add item'),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (items.isEmpty)
                  _EmptyState(onAdd: () => _openExpenseEditor(context))
                else
                  ...items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _FixedExpenseTile(
                        item: item,
                        onChanged: (value) async {
                          final userId = resolveSignedInUserId(context) ?? '';
                          await context
                              .read<FixedExpenseProvider>()
                              .edit(_copyWithActive(item, value, userId));
                        },
                        onEdit: () => _openExpenseEditor(context, item: item),
                        onDelete: () => _confirmDelete(context, item),
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).inputDecorationTheme.fillColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.notifications_active_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('다음 자동 반영 예정', 'Next scheduled entry'),
                              style: AppTextStyles.labelMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              upcomingItem == null
                                  ? context.tr(
                                      '활성화된 고정 입출금이 없어요.',
                                      'There are no active recurring entries.',
                                    )
                                  : '${context.formatDueDay(upcomingItem.billingDay)} ${upcomingItem.title} ${context.formatCurrency(upcomingItem.amount)}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.68),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  FixedExpense _copyWithActive(FixedExpense item, bool isActive, String userId) {
    return FixedExpense(
      id: item.id,
      userId: userId.isNotEmpty ? userId : item.userId,
      categoryId: item.categoryId,
      title: item.title,
      amount: item.amount,
      cycle: item.cycle,
      billingDay: item.billingDay,
      nextDueDate: item.nextDueDate,
      memo: item.memo,
      isActive: isActive,
      createdAt: item.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _confirmDelete(BuildContext context, FixedExpense item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(context.tr('고정 항목 삭제', 'Delete recurring entry')),
          content: Text(
            context.tr(
              '${item.title} 항목을 목록에서 제거할까요?',
              'Remove ${item.title} from the list?',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.tr('취소', 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(context.tr('삭제', 'Delete')),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      await context.read<FixedExpenseProvider>().remove(item.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              '${item.title} 항목을 삭제했어요.',
              '${item.title} has been removed.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _openExpenseEditor(
    BuildContext context, {
    FixedExpense? item,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return _FixedExpenseEditorSheet(item: item);
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String helper;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.helper,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final secondaryTextColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.68);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: secondaryTextColor),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
              style: AppTextStyles.titleLarge.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            helper,
            style: AppTextStyles.bodySmall.copyWith(
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _FixedExpenseTile extends StatelessWidget {
  final FixedExpense item;
  final ValueChanged<bool> onChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FixedExpenseTile({
    required this.item,
    required this.onChanged,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const amountColor = AppColors.expense;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.receipt_long_outlined,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title, style: AppTextStyles.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            context.tr(
                              '매월 ${item.billingDay}일 · ${item.memo ?? (item.cycle == 'monthly' ? '월정기' : '연정기')}',
                              'Day ${item.billingDay} monthly · ${item.memo ?? (item.cycle == 'monthly' ? 'monthly' : 'yearly')}',
                            ),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.68),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: item.isActive,
                      onChanged: onChanged,
                      activeThumbColor: AppColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '-${_formatAmount(item.amount)}원',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: amountColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: onDelete,
                      child: Text(
                        '삭제',
                        style: AppTextStyles.caption.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.68),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: onEdit,
                      child: Text(
                        '수정',
                        style: AppTextStyles.caption.copyWith(
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
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 38,
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          Text(
            '등록된 고정 항목이 없어요',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '월세, 통신비, 월급, 용돈처럼 반복되는 입출금을 추가해보세요.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.68),
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: onAdd,
            child: const Text('고정 항목 추가'),
          ),
        ],
      ),
    );
  }
}

class _FixedExpenseEditorSheet extends StatefulWidget {
  final FixedExpense? item;

  const _FixedExpenseEditorSheet({this.item});

  @override
  State<_FixedExpenseEditorSheet> createState() =>
      _FixedExpenseEditorSheetState();
}

class _FixedExpenseEditorSheetState extends State<_FixedExpenseEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _dueDayController;
  late final TextEditingController _memoController;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _titleController = TextEditingController(text: item?.title ?? '');
    _amountController =
        TextEditingController(text: item == null ? '' : item.amount.toString());
    _dueDayController =
        TextEditingController(text: item == null ? '' : item.billingDay.toString());
    _memoController = TextEditingController(text: item?.memo ?? '');
    _isActive = item?.isActive ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _dueDayController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const _EditorLabel('항목 이름'),
              const SizedBox(height: 6),
              _EditorTextField(
                controller: _titleController,
                hintText: '예: 월세, 통신비',
              ),
              const SizedBox(height: 12),
              const _EditorLabel('금액'),
              const SizedBox(height: 6),
              _EditorTextField(
                controller: _amountController,
                hintText: '숫자만 입력',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              const _EditorLabel('결제일'),
              const SizedBox(height: 6),
              _EditorTextField(
                controller: _dueDayController,
                hintText: '1~31',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _submit(context),
                  child: Text(isEditing ? '수정 완료' : '저장'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    final title = _titleController.text.trim();
    final amount = int.tryParse(_amountController.text.trim());
    final dueDay = int.tryParse(_dueDayController.text.trim());
    final memo = _memoController.text.trim();

    if (title.isEmpty ||
        amount == null ||
        dueDay == null ||
        dueDay < 1 ||
        dueDay > 31) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름, 금액, 결제일을 올바르게 입력해 주세요.')),
      );
      return;
    }

    String userId = resolveSignedInUserId(context) ?? '';
    if (userId.isEmpty) {
      try {
        userId = context.read<AuthProvider>().user?.id ?? '';
      } catch (_) {}
    }
    final provider = context.read<FixedExpenseProvider>();
    final nav = Navigator.of(context);
    final existingItem = widget.item;

    if (existingItem == null) {
      await provider.add(FixedExpense(
        id: '',
        userId: userId,
        title: title,
        amount: amount,
        cycle: 'monthly',
        billingDay: dueDay,
        memo: memo.isEmpty ? null : memo,
        isActive: _isActive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    } else {
      await provider.edit(FixedExpense(
        id: existingItem.id,
        userId: existingItem.userId,
        categoryId: existingItem.categoryId,
        title: title,
        amount: amount,
        cycle: existingItem.cycle,
        billingDay: dueDay,
        nextDueDate: existingItem.nextDueDate,
        memo: memo.isEmpty ? null : memo,
        isActive: _isActive,
        createdAt: existingItem.createdAt,
        updatedAt: DateTime.now(),
      ));
    }

    if (!mounted) return;
    nav.pop();
  }
}

class _EditorLabel extends StatelessWidget {
  final String text;

  const _EditorLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _EditorTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;

  const _EditorTextField({
    required this.controller,
    required this.hintText,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      ),
    );
  }
}

String _formatAmount(int amount) {
  return amount
      .toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) {
    return '${m[1]},';
  });
}
