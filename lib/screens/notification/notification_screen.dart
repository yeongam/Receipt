import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/signed_in_user_id.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/fixed_expense.dart';
import '../../providers/fixed_expense_provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FixedExpenseProvider>();
    final items = provider.items;
    final activeItems = provider.activeItems;
    final activeTotal = activeItems.fold<int>(0, (sum, e) => sum + e.amount);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('알림 관리'),
        actions: [
          IconButton(
            onPressed: () => _openFixedExpenseSheet(context),
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '고정지출 자동 차감',
                        style: AppTextStyles.sectionTitle,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '매달 반복되는 지출을 자동으로 반영하고 알림을 관리하세요.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              label: '활성 항목',
                              value: '${activeItems.length}개',
                              helper: '전체 ${items.length}개 등록',
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SummaryCard(
                              label: '이번 달 차감',
                              value: '${_formatAmount(activeTotal)}원',
                              helper: '자동 반영 예정',
                              color: AppColors.expense,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Text(
                            '등록된 고정지출이 없습니다',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          children: [
                            Container(
                              padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '자동 차감 목록',
                                    style: AppTextStyles.titleMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '수정 가능',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...items.map(
                              (fe) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _FixedExpenseTile(
                                  title: fe.title,
                                  subtitle:
                                      '매월 ${fe.billingDay}일 · ${fe.cycle == 'monthly' ? '월정기' : '연정기'}',
                                  amount: fe.amount,
                                  isEnabled: fe.isActive,
                                  onChanged: (value) async {
                                    await provider.edit(
                                      FixedExpense(
                                        id: fe.id,
                                        userId: fe.userId,
                                        categoryId: fe.categoryId,
                                        title: fe.title,
                                        amount: fe.amount,
                                        cycle: fe.cycle,
                                        billingDay: fe.billingDay,
                                        nextDueDate: fe.nextDueDate,
                                        memo: fe.memo,
                                        isActive: value,
                                        createdAt: fe.createdAt,
                                        updatedAt: fe.updatedAt,
                                      ),
                                    );
                                  },
                                ),
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

Future<void> _openFixedExpenseSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _FixedExpenseEntrySheet(),
  );
}

class _FixedExpenseEntrySheet extends StatefulWidget {
  const _FixedExpenseEntrySheet();

  @override
  State<_FixedExpenseEntrySheet> createState() =>
      _FixedExpenseEntrySheetState();
}

class _FixedExpenseEntrySheetState extends State<_FixedExpenseEntrySheet> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _billingDayController = TextEditingController();
  String _cycle = 'monthly';

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _billingDayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('고정지출 추가', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 16),
            _InputField(
              controller: _titleController,
              label: '항목명',
              hintText: '예: 월세, 통신비',
            ),
            const SizedBox(height: 12),
            _InputField(
              controller: _amountController,
              label: '금액',
              hintText: '숫자만 입력',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            _InputField(
              controller: _billingDayController,
              label: '결제일',
              hintText: '1~31',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            const Text('주기', style: AppTextStyles.labelMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _cycle,
              items: const [
                DropdownMenuItem(value: 'monthly', child: Text('매월')),
                DropdownMenuItem(value: 'yearly', child: Text('매년')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _cycle = value);
              },
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final amount = int.tryParse(_amountController.text.trim());
                  final billingDay = int.tryParse(
                    _billingDayController.text.trim(),
                  );
                  final userId = resolveSignedInUserId(context) ?? '';
                  if (_titleController.text.trim().isEmpty ||
                      amount == null ||
                      amount <= 0 ||
                      billingDay == null ||
                      billingDay < 1 ||
                      billingDay > 31 ||
                      userId.isEmpty) {
                    return;
                  }

                  await context.read<FixedExpenseProvider>().add(
                    createFixedExpenseDraft(
                      userId: userId,
                      title: _titleController.text.trim(),
                      amount: amount,
                      billingDay: billingDay,
                      cycle: _cycle,
                    ),
                  );
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                },
                child: const Text('저장'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

FixedExpense createFixedExpenseDraft({
  required String userId,
  required String title,
  required int amount,
  required int billingDay,
  String cycle = 'monthly',
  DateTime? now,
}) {
  final timestamp = now ?? DateTime.now();
  return FixedExpense(
    id: '',
    userId: userId,
    title: title,
    amount: amount,
    cycle: cycle,
    billingDay: billingDay,
    isActive: true,
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    required this.hintText,
    this.keyboardType = TextInputType.text,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelMedium),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(hintText: hintText),
        ),
      ],
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.titleLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            helper,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FixedExpenseTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final int amount;
  final bool isEnabled;
  final ValueChanged<bool> onChanged;

  const _FixedExpenseTile({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
            child: const Icon(
              Icons.repeat_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: AppTextStyles.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isEnabled,
                      onChanged: onChanged,
                      activeThumbColor: AppColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${_formatAmount(amount)}원',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.expense,
                    fontWeight: FontWeight.w700,
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

String _formatAmount(int amount) {
  return amount.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) {
      return '${m[1]},';
    },
  );
}
