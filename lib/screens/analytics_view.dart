import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';

class AnalyticsView extends ConsumerStatefulWidget {
  const AnalyticsView({Key? key}) : super(key: key);

  @override
  ConsumerState<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends ConsumerState<AnalyticsView> {
  int touchedIndex = -1;

  Color _getCategoryColor(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('food') || lower.contains('dining')) return Colors.orange;
    if (lower.contains('transport') || lower.contains('taxi')) return Colors.cyan;
    if (lower.contains('shopping')) return Colors.purple;
    return AppTheme.primaryIndigo;
  }

  IconData _getCategoryIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('food') || lower.contains('dining')) return Icons.restaurant_rounded;
    if (lower.contains('transport') || lower.contains('taxi')) return Icons.directions_car_rounded;
    if (lower.contains('shopping')) return Icons.shopping_bag_rounded;
    return Icons.receipt_long_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsyncValue = ref.watch(transactionsProvider);
    final currency = ref.watch(currencyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: transactionsAsyncValue.when(
        data: (transactions) {
          final now = DateTime.now();
          final expenses = transactions.where((t) => t.type == 'expense' && t.date.month == now.month && t.date.year == now.year).toList();

          if (expenses.isEmpty) {
            return Center(child: Text('No expense data this month.', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))));
          }

          Map<String, double> categoryTotals = {};
          double totalExpense = 0;
          for (var tx in expenses) {
            categoryTotals[tx.category] = (categoryTotals[tx.category] ?? 0) + tx.amount;
            totalExpense += tx.amount;
          }

          List<PieChartSectionData> pieChartSections = [];
          int i = 0;

          categoryTotals.forEach((category, amount) {
            final isTouched = i == touchedIndex;
            final radius = isTouched ? 35.0 : 25.0;
            final color = _getCategoryColor(category);

            pieChartSections.add(
              PieChartSectionData(
                color: color,
                value: amount,
                title: '', // Don't show text on slices for a cleaner look
                radius: radius,
              )
            );
            i++;
          });

          // Sort categories by amount descending
          final sortedCategories = categoryTotals.keys.toList()..sort((a, b) => categoryTotals[b]!.compareTo(categoryTotals[a]!));

          return Column(
            children: [
              const SizedBox(height: 32),
              // Donut Chart
              SizedBox(
                height: 250,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                touchedIndex = -1;
                                return;
                              }
                              touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 2,
                        centerSpaceRadius: 80,
                        sections: pieChartSections,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Total Spent', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14)),
                        const SizedBox(height: 4),
                        Text('$currency${totalExpense.toStringAsFixed(0)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Category Breakdown List
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                  decoration: const BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Top Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: sortedCategories.length,
                          itemBuilder: (context, index) {
                            final category = sortedCategories[index];
                            final amount = categoryTotals[category]!;
                            final percentage = amount / totalExpense;
                            final color = _getCategoryColor(category);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44, height: 44,
                                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                                    child: Icon(_getCategoryIcon(category), color: color, size: 20),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(category, style: const TextStyle(fontWeight: FontWeight.w600)),
                                            Text('$currency${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: LinearProgressIndicator(
                                            value: percentage,
                                            backgroundColor: Colors.white.withValues(alpha: 0.05),
                                            color: color,
                                            minHeight: 6,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      )
    );
  }
}
