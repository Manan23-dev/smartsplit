import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../models/expense.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smartsplit'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, expenseProvider, child) {
          if (expenseProvider.expenses.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No expenses yet!',
                    style: TextStyle(fontSize: 20, color: Colors.grey),
                  ),
                  Text(
                    'Add your first expense - it will sync to the cloud!',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Summary Card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.blue, Colors.purple],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_done, color: Colors.white, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Expenses (Cloud Synced)',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          Text(
                            NumberFormat.currency(symbol: '\$').format(expenseProvider.totalExpenses),
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Expenses List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: expenseProvider.expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenseProvider.expenses[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          child: const Icon(Icons.receipt, color: Colors.blue),
                        ),
                        title: Text(expense.title),
                        subtitle: Text(
                          '${expense.category} • ${DateFormat('MMM dd, yyyy').format(expense.date)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  NumberFormat.currency(symbol: '\$').format(expense.amount),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const Icon(Icons.cloud_done, color: Colors.green, size: 16),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              onPressed: () => _deleteExpense(context, expense.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpenseDialog(context),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String selectedCategory = 'Food';
    
    final categories = ['Food', 'Transport', 'Entertainment', 'Shopping', 'Bills', 'Other'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Expense'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Expense Title',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount (\$)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                Consumer<ExpenseProvider>(
                  builder: (context, expenseProvider, child) {
                    return ElevatedButton(
                      onPressed: expenseProvider.isLoading 
                          ? null 
                          : () => _addExpense(context, titleController, amountController, selectedCategory),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: expenseProvider.isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Add to Cloud'),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addExpense(BuildContext context, TextEditingController titleController, 
                   TextEditingController amountController, String category) async {
    if (titleController.text.isNotEmpty && amountController.text.isNotEmpty) {
      final authService = AuthService();
      final currentUser = authService.currentUser;
      
      if (currentUser != null) {
        final expense = Expense(
          title: titleController.text,
          amount: double.tryParse(amountController.text) ?? 0.0,
          date: DateTime.now(),
          category: category,
          userId: currentUser.uid,
        );
        
        final success = await context.read<ExpenseProvider>().addExpense(expense);
        
        if (success && context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('💸 Expense added and synced to cloud!'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Failed to add expense'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _deleteExpense(BuildContext context, String expenseId) async {
    final success = await context.read<ExpenseProvider>().deleteExpense(expenseId);
    
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🗑️ Expense deleted from cloud!'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Failed to delete expense'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<AuthProvider>().signOut();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}