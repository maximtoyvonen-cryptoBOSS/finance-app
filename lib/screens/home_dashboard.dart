import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../models/transaction_model.dart';
import '../theme/app_theme.dart';

class HomeDashboard extends ConsumerStatefulWidget {
  const HomeDashboard({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends ConsumerState<HomeDashboard> {
  final TextEditingController _inputController = TextEditingController();
  bool _isProcessing = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    ref.read(voiceServiceProvider).initialize();
  }

  void _submitInput(String text) async {
    if (text.isEmpty) return;
    setState(() => _isProcessing = true);

    final success = await ref.read(transactionsProvider.notifier).addTransactionFromInput(text);

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (success) {
      _inputController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction added!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to add transaction.')));
    }
  }

  void _toggleVoiceInput() {
    final voiceService = ref.read(voiceServiceProvider);
    if (!voiceService.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Voice input not available')));
      return;
    }

    if (_isListening) {
      voiceService.stopListening();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      voiceService.startListening((text) {
        _inputController.text = text;
        if (!voiceService.isListening) {
           setState(() => _isListening = false);
           _submitInput(text);
        }
      });
    }
  }

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
    final budgetsAsyncValue = ref.watch(budgetsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Overview', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            // Hero Balance Card
            transactionsAsyncValue.when(
              data: (transactions) {
                double totalIncome = 0;
                double totalExpense = 0;
                final now = DateTime.now();
                for (var tx in transactions) {
                  if (tx.date.month == now.month && tx.date.year == now.year) {
                    if (tx.type == 'income') {
                      totalIncome += tx.amount;
                    } else {
                      totalExpense += tx.amount;
                    }
                  }
                }
                final balance = totalIncome - totalExpense;

                return Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
                  child: Column(
                    children: [
                      Text('Monthly Balance', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14)),
                      const SizedBox(height: 8),
                      Text('$ ${balance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.incomeGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.arrow_downward, color: AppTheme.incomeGreen, size: 16),
                                const SizedBox(width: 4),
                                Text('$${totalIncome.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.incomeGreen, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.expenseRose.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.arrow_upward, color: AppTheme.expenseRose, size: 16),
                                const SizedBox(width: 4),
                                Text('$${totalExpense.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.expenseRose, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              },
              loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
              error: (err, stack) => SizedBox(height: 120, child: Center(child: Text('Error: $err'))),
            ),

            // Budget Summary
            budgetsAsyncValue.when(
              data: (budgets) {
                if (budgets.isEmpty) return const SizedBox.shrink();
                final overall = budgets.firstWhere((b) => b.category == 'Overall', orElse: () => budgets.first);

                double spent = 0;
                if (transactionsAsyncValue is AsyncData) {
                  final txs = transactionsAsyncValue.value!;
                  final now = DateTime.now();
                  for (var tx in txs) {
                      if (tx.type == 'expense' && tx.date.month == now.month && tx.date.year == now.year) {
                        spent += tx.amount;
                      }
                  }
                }

                final progress = overall.amount > 0 ? (spent / overall.amount).clamp(0.0, 1.0) : 0.0;
                final isWarning = progress >= 0.8;
                final isDanger = progress >= 1.0;

                Color progressColor = AppTheme.incomeGreen;
                if (isDanger) {
                  progressColor = AppTheme.expenseRose;
                } else if (isWarning) {
                  progressColor = Colors.amber;
                }

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Monthly Budget', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: progressColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('${(progress * 100).toStringAsFixed(0)}%', style: TextStyle(color: progressColor, fontWeight: FontWeight.bold, fontSize: 12)),
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white.withValues(alpha: 0.05),
                            color: progressColor,
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('$ ${spent.toStringAsFixed(0)} spent', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                            Text('$ ${overall.amount.toStringAsFixed(0)} limit', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (err, stack) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),

            // Recent Transactions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {}, // Handled by nav bar in a real app, maybe jump to history tab
                  child: const Text('See all', style: TextStyle(color: AppTheme.primaryIndigo)),
                )
              ],
            ),
            Expanded(
              child: transactionsAsyncValue.when(
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return const Center(child: Text('No transactions yet.', style: TextStyle(color: Colors.grey)));
                  }
                  return ListView.builder(
                    itemCount: transactions.length > 5 ? 5 : transactions.length,
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      final isIncome = tx.type == 'income';
                      final catColor = _getCategoryColor(tx.category);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Card(
                          margin: EdgeInsets.zero,
                          color: Colors.transparent,
                          elevation: 0,
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                color: catColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getCategoryIcon(tx.category),
                                color: catColor,
                              ),
                            ),
                            title: Text(tx.category, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(tx.note, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: Text(
                              "${isIncome ? '+' : '-'}$${tx.amount.toStringAsFixed(2)}",
                              style: TextStyle(
                                color: isIncome ? AppTheme.incomeGreen : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),

            // Input Bar
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        decoration: InputDecoration(
                          hintText: 'e.g. Lunch 650',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                          fillColor: Colors.transparent,
                          suffixIcon: _isProcessing
                              ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))
                              : IconButton(
                                  icon: const Icon(Icons.send_rounded, color: AppTheme.primaryIndigo),
                                  onPressed: () => _submitInput(_inputController.text),
                                ),
                        ),
                        onSubmitted: _submitInput,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GestureDetector(
                        onTap: _toggleVoiceInput,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: _isListening ? AppTheme.expenseRose : AppTheme.primaryIndigo.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isListening ? Icons.mic_off : Icons.mic,
                            color: _isListening ? Colors.white : AppTheme.primaryIndigo,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
