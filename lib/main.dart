import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'firebase_options.dart';
import 'services/firebase_service.dart';
import 'models/expense.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ExpenseProvider(),
      child: MaterialApp(
        title: 'Smartsplit',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

// Auth Wrapper - decides between login and home screen
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.hasData) {
          return HomeScreen(); // User is logged in
        } else {
          return LoginScreen(); // User is not logged in
        }
      },
    );
  }
}

// Your existing Expense class (updated for Firebase)
class Expense {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final String userId;

  Expense({
    String? id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.userId,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.millisecondsSinceEpoch,
      'category': category,
      'userId': userId,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] ?? 0),
      category: map['category'] ?? 'Other',
      userId: map['userId'] ?? '',
    );
  }
}

// Updated Expense Provider for Firebase
class ExpenseProvider with ChangeNotifier {
  List<Expense> _expenses = [];
  bool _isLoading = false;

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;

  double get totalExpenses {
    return _expenses.fold(0, (sum, expense) => sum + expense.amount);
  }

  // Listen to Firebase stream
  void listenToExpenses() {
    FirebaseService.getUserExpenses().listen((expenses) {
      _expenses = expenses;
      notifyListeners();
    });
  }

  Future<void> addExpense(Expense expense) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await FirebaseService.addExpense(expense);
    } catch (e) {
      print('Error adding expense: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> removeExpense(String id) async {
    try {
      await FirebaseService.deleteExpense(id);
    } catch (e) {
      print('Error deleting expense: $e');
    }
  }
}

// Login Screen
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet, size: 80, color: Colors.white),
                  SizedBox(height: 16),
                  Text('Smartsplit', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 8),
                  Text('Smart expense tracking with cloud sync', style: TextStyle(fontSize: 16, color: Colors.white70)),
                  SizedBox(height: 48),
                  
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Text(_isSignUp ? 'Create Account' : 'Welcome Back', 
                               style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          SizedBox(height: 24),
                          
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          SizedBox(height: 16),
                          
                          TextField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            obscureText: true,
                          ),
                          SizedBox(height: 24),
                          
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleAuth,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF667eea),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isLoading 
                                  ? CircularProgressIndicator(color: Colors.white)
                                  : Text(_isSignUp ? 'Sign Up' : 'Sign In', style: TextStyle(fontSize: 16)),
                            ),
                          ),
                          SizedBox(height: 16),
                          
                          TextButton(
                            onPressed: () => setState(() => _isSignUp = !_isSignUp),
                            child: Text(_isSignUp ? 'Already have account? Sign In' : 'Need account? Sign Up'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleAuth() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    String? error;
    if (_isSignUp) {
      error = await FirebaseService.signUp(_emailController.text.trim(), _passwordController.text.trim());
    } else {
      error = await FirebaseService.signIn(_emailController.text.trim(), _passwordController.text.trim());
    }

    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }
}

// Updated Home Screen with Firebase
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Start listening to Firebase expenses
    Provider.of<ExpenseProvider>(context, listen: false).listenToExpenses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Smartsplit Cloud'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseService.signOut();
            },
          ),
        ],
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, expenseProvider, child) {
          if (expenseProvider.expenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No expenses yet!', style: TextStyle(fontSize: 20, color: Colors.grey)),
                  Text('Add your first cloud expense!', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Cloud Summary Card
              Container(
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.blue, Colors.purple]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cloud_done, color: Colors.white, size: 32),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Expenses (Cloud Synced)', style: TextStyle(color: Colors.white70, fontSize: 14)),
                          Text(
                            NumberFormat.currency(symbol: '\$').format(expenseProvider.totalExpenses),
                            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
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
                  padding: EdgeInsets.all(16),
                  itemCount: expenseProvider.expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenseProvider.expenses[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          child: Icon(Icons.receipt, color: Colors.blue),
                        ),
                        title: Text(expense.title),
                        subtitle: Text('${expense.category} • ${DateFormat('MMM dd, yyyy').format(expense.date)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  NumberFormat.currency(symbol: '\$').format(expense.amount),
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Icon(Icons.cloud_done, color: Colors.green, size: 16),
                              ],
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red, size: 20),
                              onPressed: () => expenseProvider.removeExpense(expense.id),
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
        icon: Icon(Icons.add),
        label: Text('Add Expense'),
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
              title: Text('Add Cloud Expense'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Expense Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    decoration: InputDecoration(
                      labelText: 'Amount (\$)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: categories.map((category) {
                      return DropdownMenuItem(value: category, child: Text(category));
                    }).toList(),
                    onChanged: (value) => setState(() => selectedCategory = value!),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isNotEmpty && amountController.text.isNotEmpty) {
                      final expense = Expense(
                        title: titleController.text,
                        amount: double.tryParse(amountController.text) ?? 0.0,
                        date: DateTime.now(),
                        category: selectedCategory,
                        userId: FirebaseService.currentUser!.uid,
                      );
                      
                      await Provider.of<ExpenseProvider>(context, listen: false).addExpense(expense);
                      Navigator.of(context).pop();
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Expense synced to cloud!'), backgroundColor: Colors.green),
                      );
                    }
                  },
                  child: Text('Add to Cloud'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

