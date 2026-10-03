import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../providers/providers.dart';
import '../models/transaction_model.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  Future<void> _exportToCSV(BuildContext context, List<TransactionModel> transactions) async {
    List<List<dynamic>> rows = [];
    rows.add(["ID", "Date", "Category", "Amount", "Type", "Note"]);

    for (var tx in transactions) {
      rows.add([tx.id, tx.date.toIso8601String(), tx.category, tx.amount, tx.type, tx.note]);
    }

    String csv = rows.map((r) => r.map((cell) => '"${cell.toString().replaceAll('"', '""')}"').join(',')).join('\n');

    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/transactions_export.csv';
    final file = File(path);
    await file.writeAsString(csv);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported to $path')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsyncValue = ref.watch(transactionsProvider);
    final currency = ref.watch(currencyProvider);
    final currencies = ['\$', '€', '£', '¥', '₽', '₸'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const Padding(
             padding: EdgeInsets.all(16.0),
             child: Text('General Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ListTile(
             leading: const Icon(Icons.attach_money),
             title: const Text('Currency'),
             trailing: DropdownButton<String>(
               value: currency,
               underline: const SizedBox(),
               items: currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
               onChanged: (value) {
                 if (value != null) {
                   ref.read(currencyProvider.notifier).setCurrency(value);
                 }
               },
             ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Data Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Export to CSV'),
            onTap: () {
               transactionsAsyncValue.whenData((transactions) {
                 _exportToCSV(context, transactions);
               });
            },
          ),
          const Divider(),
          const Padding(
             padding: EdgeInsets.all(16.0),
             child: Text('Budget Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ListTile(
             leading: const Icon(Icons.edit),
             title: const Text('Set Monthly Budget'),
             onTap: () {
               showDialog(
                 context: context,
                 builder: (ctx) {
                   final controller = TextEditingController();
                   return AlertDialog(
                     title: const Text('Set Budget'),
                     content: TextField(
                       controller: controller,
                       keyboardType: TextInputType.number,
                       decoration: const InputDecoration(labelText: 'Amount'),
                     ),
                     actions: [
                       TextButton(
                         onPressed: () => Navigator.pop(ctx),
                         child: const Text('Cancel')
                       ),
                       TextButton(
                         onPressed: () {
                           final amount = double.tryParse(controller.text) ?? 0.0;
                           if (amount > 0) {
                             final now = DateTime.now();
                             ref.read(budgetsProvider.notifier).addBudget(amount, 'Overall', now.month, now.year);
                           }
                           Navigator.pop(ctx);
                         },
                         child: const Text('Save')
                       )
                     ]
                   );
                 }
               );
             },
          )
        ],
      ),
    );
  }
}
