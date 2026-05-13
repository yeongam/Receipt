import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/signed_in_user_id.dart';
import '../../data/models/category.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import 'settings_widgets.dart';

class CategorySettingsScreen extends StatelessWidget {
  const CategorySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider?>();
    final categoryProvider = context.watch<CategoryProvider>();
    final userId = authProvider?.user?.id ?? resolveSignedInUserId(context) ?? '';

    return SettingsScaffold(
      title: '분류 관리',
      children: [
        _CategoryCard(
          title: '출금 분류',
          categories: categoryProvider.expenseCategories,
          onAdd: (value) => _addCategory(
            context,
            userId: userId,
            name: value,
            type: 'expense',
          ),
          onRemove: (value) =>
              context.read<CategoryProvider>().deleteCategory(value.id),
        ),
        _CategoryCard(
          title: '입금 분류',
          categories: categoryProvider.incomeCategories,
          onAdd: (value) => _addCategory(
            context,
            userId: userId,
            name: value,
            type: 'income',
          ),
          onRemove: (value) =>
              context.read<CategoryProvider>().deleteCategory(value.id),
        ),
      ],
    );
  }
}

Future<void> _addCategory(
  BuildContext context, {
  required String userId,
  required String name,
  required String type,
}) async {
  final trimmed = name.trim();
  if (trimmed.isEmpty || userId.isEmpty) return;

  final existing = context.read<CategoryProvider>().categories.any(
    (category) => category.type == type && category.name == trimmed,
  );
  if (existing) return;

  await context.read<CategoryProvider>().addCategory(
    AppCategory(
      id: '',
      userId: userId,
      name: trimmed,
      type: type,
      icon: type == 'income' ? 'payments' : 'category',
      colorHex: type == 'income' ? '#29B6F6' : '#607D8B',
      isDefault: false,
      createdAt: DateTime.now(),
    ),
  );
}

class _CategoryCard extends StatefulWidget {
  final String title;
  final List<AppCategory> categories;
  final Future<void> Function(String value) onAdd;
  final Future<void> Function(AppCategory category) onRemove;

  const _CategoryCard({
    required this.title,
    required this.categories,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      title: widget.title,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.categories
              .map(
                (category) => Chip(
                  label: Text(category.name),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => widget.onRemove(category),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(hintText: '새 분류 입력'),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () async {
                final focusScope = FocusScope.of(context);
                await widget.onAdd(_controller.text);
                _controller.clear();
                focusScope.unfocus();
              },
              child: const Text('추가'),
            ),
          ],
        ),
      ],
    );
  }
}
