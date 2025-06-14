import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../models/expense.dart';
import 'camera_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isFabExpanded = false;

  @override
  void initState() {
    super.initState();
    // Start listening to expenses when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ExpenseProvider>().listenToExpenses();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smartsplit'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().signOut();
            },
          ),
        ],
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, expenseProvider, child) {
          if (expenseProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (expenseProvider.expenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No expenses yet!',
                    style: TextStyle(fontSize: 20, color: Colors.grey),
                  ),
                  Text(
                    'Add your first expense or scan a receipt',
                    style: TextStyle(color: Colors.grey),
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
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet, 
                              color: Colors.white, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Expenses',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            NumberFormat.currency(symbol: '\$')
                                .format(expenseProvider.totalExpenses),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: expenseProvider.expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenseProvider.expenses[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getCategoryColor(expense.category).withOpacity(0.1),
                          child: Icon(
                            _getCategoryIcon(expense.category), 
                            color: _getCategoryColor(expense.category),
                          ),
                        ),
                        title: Text(expense.title),
                        subtitle: Text(
                          '${expense.category} • ${DateFormat('MMM dd, yyyy').format(expense.date)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              NumberFormat.currency(symbol: '\$')
                                  .format(expense.amount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _showDeleteDialog(expense.id),
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
      floatingActionButton: _buildExpandableFab(),
    );
  }

  Widget _buildExpandableFab() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Camera FAB
        if (_isFabExpanded) ...[
          FloatingActionButton(
            onPressed: _openCamera,
            backgroundColor: Colors.orange,
            heroTag: "camera",
            child: const Icon(Icons.camera_alt, color: Colors.white),
          ),
          const SizedBox(height: 16),
          
          // Manual Add FAB
          FloatingActionButton(
            onPressed: _showAddExpenseDialog,
            backgroundColor: Colors.green,
            heroTag: "manual",
            child: const Icon(Icons.add, color: Colors.white),
          ),
          const SizedBox(height: 16),
        ],
        
        // Main FAB
        FloatingActionButton.extended(
          onPressed: () {
            setState(() {
              _isFabExpanded = !_isFabExpanded;
            });
          },
          backgroundColor: const Color(0xFF667eea),
          foregroundColor: Colors.white,
          icon: Icon(_isFabExpanded ? Icons.close : Icons.add),
          label: Text(_isFabExpanded ? 'Close' : 'Add Expense'),
        ),
      ],
    );
  }

  void _openCamera() {
    setState(() {
      _isFabExpanded = false;
    });
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CameraScreen(
          onReceiptScanned: _handleReceiptScanned,
        ),
      ),
    );
  }

  void _handleReceiptScanned(Map<String, dynamic> receiptData) async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not authenticated'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final expense = Expense(
      title: receiptData['title'],
      amount: receiptData['amount'],
      date: receiptData['date'],
      category: receiptData['category'],
      userId: authProvider.user!.uid,
    );

    final success = await context.read<ExpenseProvider>().addExpense(expense);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
              ? 'Receipt scanned and expense added!' 
              : 'Failed to add expense'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Transport':
        return Icons.directions_car;
      case 'Entertainment':
        return Icons.movie;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Bills':
        return Icons.receipt;
      case 'Health':
        return Icons.local_hospital;
      default:
        return Icons.category;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food':
        return Colors.orange;
      case 'Transport':
        return Colors.blue;
      case 'Entertainment':
        return Colors.purple;
      case 'Shopping':
        return Colors.green;
      case 'Bills':
        return Colors.red;
      case 'Health':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  void _showAddExpenseDialog() {
    setState(() {
      _isFabExpanded = false;
    });

    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String selectedCategory = 'Food';
    
    final categories = [
      'Food', 'Transport', 'Entertainment', 
      'Shopping', 'Bills', 'Health', 'Other'
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Expense'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Expense Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount (\$)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => selectedCategory = value!),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => _addExpense(
                    titleController.text,
                    amountController.text,
                    selectedCategory,
                  ),
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addExpense(String title, String amountText, String category) async {
    if (title.isEmpty || amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not authenticated'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final expense = Expense(
      title: title,
      amount: amount,
      date: DateTime.now(),
      category: category,
      userId: authProvider.user!.uid,
    );

    final success = await context.read<ExpenseProvider>().addExpense(expense);
    
    if (mounted) {
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
              ? 'Expense added successfully!' 
              : 'Failed to add expense'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _showDeleteDialog(String expenseId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Expense'),
          content: const Text('Are you sure you want to delete this expense?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _deleteExpense(expenseId),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _deleteExpense(String expenseId) async {
    final success = await context.read<ExpenseProvider>().deleteExpense(expenseId);
    
    if (mounted) {
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
              ? 'Expense deleted successfully!' 
              : 'Failed to delete expense'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}