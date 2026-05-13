import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/amount_format.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('리포트'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: '출금 분석'),
            Tab(text: '월별 추이'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _SpendingAnalysisTab(),
          _MonthlyTrendTab(),
        ],
      ),
    );
  }
}

class _SpendingAnalysisTab extends StatelessWidget {
  const _SpendingAnalysisTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final month = provider.selectedMonth;
    final totalExpense = provider.totalExpenseForMonth(month);
    final categoryNames = {
      for (final c in categoryProvider.categories) c.id: c.name,
    };
    final categories = provider.expenseCategoriesForMonth(month, categoryNames);

    final prevYear = month.month == 1 ? month.year - 1 : month.year;
    final prevMonthNum = month.month == 1 ? 12 : month.month - 1;
    final prevTrend = provider.monthlyTrends.where((t) =>
        t.month.year == prevYear && t.month.month == prevMonthNum);
    final previousExpense = prevTrend.isEmpty ? 0 : prevTrend.first.expense;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('${month.year}년 ${month.month}월', style: AppTextStyles.titleMedium),
        const SizedBox(height: 16),
        _DonutChartCard(
          totalExpense: totalExpense,
          categories: categories,
        ),
        const SizedBox(height: 16),
        _ComparisonCard(
          currentExpense: totalExpense,
          previousExpense: previousExpense,
        ),
      ],
    );
  }
}

class _DonutChartCard extends StatelessWidget {
  final int totalExpense;
  final List<CategorySummary> categories;

  const _DonutChartCard({
    required this.totalExpense,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    const palette = AppColors.chartPalette;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
          const Text('카테고리별 출금', style: AppTextStyles.titleMedium),
          const SizedBox(height: 4),
          Text('${formatAmount(totalExpense)}원 출금',
              style:
                  AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(180, 180),
                    painter: _DonutPainter(
                      categories: categories,
                      palette: palette,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('총 출금',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary)),
                      Text(formatAmount(totalExpense),
                          style: AppTextStyles.amountSmall.copyWith(fontSize: 20)),
                      Text('원',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ...categories.asMap().entries.map((entry) {
            final ratio = totalExpense == 0 ? 0.0 : entry.value.amount / totalExpense;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: palette[entry.key % palette.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(entry.value.categoryName, style: AppTextStyles.bodySmall),
                  ),
                  Text(
                    '${formatAmount(entry.value.amount)}원',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(ratio * 100).toStringAsFixed(0)}%',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<CategorySummary> categories;
  final List<Color> palette;

  const _DonutPainter({
    required this.categories,
    required this.palette,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = categories.fold<int>(0, (sum, item) => sum + item.amount);
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 28.0;
    double startAngle = -math.pi / 2;

    for (var index = 0; index < categories.length; index++) {
      final category = categories[index];
      final sweepAngle = (category.amount / total) * 2 * math.pi;
      final paint = Paint()
        ..color = palette[index % palette.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle - 0.04,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is! _DonutPainter) return true;

    if (!listEquals(palette, oldDelegate.palette)) {
      return true;
    }

    if (categories.length != oldDelegate.categories.length) {
      return true;
    }

    for (var i = 0; i < categories.length; i++) {
      final current = categories[i];
      final previous = oldDelegate.categories[i];
      if (current.categoryId != previous.categoryId ||
          current.categoryName != previous.categoryName ||
          current.amount != previous.amount) {
        return true;
      }
    }

    return false;
  }
}

class _ComparisonCard extends StatelessWidget {
  final int currentExpense;
  final int previousExpense;

  const _ComparisonCard({
    required this.currentExpense,
    required this.previousExpense,
  });

  @override
  Widget build(BuildContext context) {
    final difference = previousExpense - currentExpense;
    final savedMore = difference >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
          const Text('전월 대비', style: AppTextStyles.titleMedium),
          const SizedBox(height: 8),
          Text(
            previousExpense == 0
                ? '이전 달 데이터가 아직 없어요.'
                : savedMore
                    ? '지난달보다 ${formatAmount(difference)}원 적게 썼어요.'
                    : '지난달보다 ${formatAmount(difference.abs())}원 더 썼어요.',
            style: AppTextStyles.bodySmall.copyWith(
              color: savedMore ? AppColors.accent : AppColors.expense,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyTrendTab extends StatelessWidget {
  const _MonthlyTrendTab();

  @override
  Widget build(BuildContext context) {
    final trends = context.watch<TransactionProvider>().monthlyTrends;
    final maxVal = trends.fold<int>(
      1,
      (maxValue, trend) => math.max(maxValue, math.max(trend.income, trend.expense)),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
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
              const Text('월별 입금/출금', style: AppTextStyles.titleMedium),
              const SizedBox(height: 20),
              SizedBox(
                height: 170,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: trends.map((trend) {
                    final incomeHeight = 140 * (trend.income / maxVal);
                    final expenseHeight = 140 * (trend.expense / maxVal);
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  width: 12,
                                  height: incomeHeight,
                                  decoration: const BoxDecoration(
                                    color: AppColors.accent,
                                    borderRadius:
                                        BorderRadius.vertical(top: Radius.circular(4)),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  width: 12,
                                  height: expenseHeight,
                                  decoration: const BoxDecoration(
                                    color: AppColors.expense,
                                    borderRadius:
                                        BorderRadius.vertical(top: Radius.circular(4)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('${trend.month.month}월',
                                style: AppTextStyles.labelSmall),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

