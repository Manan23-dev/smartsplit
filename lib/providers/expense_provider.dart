import 'package:flutter/foundation.dart';
import '../models/expense.dart';
import '../services/firestore_service.dart';

class ExpenseProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get totalExpenses {
    return _expenses.fold(0, (sum, expense) => sum + expense.amount);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Listen to expense changes
  void listenToExpenses() {
    _firestoreService.getUserExpenses().listen((expenses) {
      _expenses = expenses;
      notifyListeners();
    });
  }

  Future<bool> addExpense(Expense expense) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firestoreService.addExpense(expense);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add expense: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteExpense(String expenseId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firestoreService.deleteExpense(expenseId);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete expense: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}