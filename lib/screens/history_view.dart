import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../models/transaction_model.dart';
import '../theme/app_theme.dart';

class HistoryView extends ConsumerStatefulWidget {
  const HistoryView({Key? key}) : super(key: key);

  @override
  ConsumerState<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends ConsumerState<HistoryView> {
  String _selectedFilter = 'All';

  IconData _getCategoryIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('food') || lower.contains('dining')) return Icons.restaurant_rounded;
    if (lower.contains('transport') || lower.contains('taxi')) return Icons.directions_car_rounded;
    if (lower.contains('shopping')) return Icons.shopping_bag_rounded;
    if (lower.contains('salary') || lower.contains('income')) return Icons.account_balance_wallet_rounded;
    return Icons.receipt_long_rounded;
  }

  Color _getCategoryColor(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('food') || lower.contains('dining')) return Colors.orange;
    if (lower.contains('transport') || lower.contains('taxi')) return Colors.cyan;
    if (lower.contains('shopping')) return Colors.purple;
    if (lower.contains('salary') || lower.contains('income')) return AppTheme.incomeGreen;
    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsyncValue = ref.watch(transactionsProvider);
    final currency = ref.watch(currencyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: ['All', 'Income', 'Expense'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedFilter = filter);
                    },
                    backgroundColor: AppTheme.surface,
                    selectedColor: AppTheme.primaryIndigo.withValues(alpha: 0.2),
                    checkmarkColor: AppTheme.primaryIndigo,
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.primaryIndigo : Colors.white.withValues(alpha: 0.6),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? AppTheme.primaryIndigo : Colors.transparent)),
                  ),
                );
              }).toList(),
            ),
          ),

          Expanded(
            child: transactionsAsyncValue.when(
              data: (transactions) {
                var filtered = transactions.where((t) {
                  if (_selectedFilter == 'All') return true;
                  if (_selectedFilter == 'Income') return t.type == 'income';
                  if (_selectedFilter == 'Expense') return t.type == 'expense';
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(child: Text('No transactions found.', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))));
                }

                // Group by day
                Map<String, List<TransactionModel>> grouped = {};
                final now = DateTime.now();
                final todayStr = DateFormat.yMMMd().format(now);
                final yesterdayStr = DateFormat.yMMMd().format(now.subtract(const Duration(days: 1)));

                for (var tx in filtered) {
                  String dateStr = DateFormat.yMMMd().format(tx.date);
                  String header = dateStr;
                  if (dateStr == todayStr) header = "Today";
                  else if (dateStr == yesterdayStr) header = "Yesterday";

                  if (!grouped.containsKey(header)) {
                    grouped[header] = [];
                  }
                  grouped[header]!.add(tx);
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: grouped.keys.length,
                  itemBuilder: (context, index) {
                    String dateStr = grouped.keys.elementAt(index);
                    List<TransactionModel> dayTxs = grouped[dateStr]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                          child: Text(dateStr, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
                        ),
                        Card(
                          margin: EdgeInsets.zero,
                          child: Column(
                            children: dayTxs.map((tx) {
                              final isIncome = tx.type == 'income';
                              final catColor = _getCategoryColor(tx.category);

                              return Dismissible(
                                key: Key(tx.id),
                                direction: DismissDirection.endToStart,
                                confirmDismiss: (direction) async {
                                  return await showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        backgroundColor: AppTheme.surface,
                                        title: const Text("Confirm Delete"),
                                        content: const Text("Are you sure you want to delete this transaction?"),
                                        actions: <Widget>[
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(false),
                                            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(true),
                                            child: const Text("Delete", style: TextStyle(color: AppTheme.expenseRose)),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                onDismissed: (direction) {
                                  ref.read(transactionsProvider.notifier).deleteTransaction(tx.id);
                                },
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20.0),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.expenseRose,
                                    borderRadius: BorderRadius.all(Radius.circular(20))
                                  ),
                                  child: const Icon(Icons.delete_outline, color: Colors.white),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  leading: Container(
                                    width: 44, height: 44,
                                    decoration: BoxDecoration(
                                      color: catColor.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _getCategoryIcon(tx.category),
                                      color: catColor,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(tx.category, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: Text(tx.note, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  trailing: Text(
                                    "${isIncome ? '+' : '-'}$currency${tx.amount.toStringAsFixed(2)}",
                                    style: TextStyle(
                                      color: isIncome ? AppTheme.incomeGreen : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
