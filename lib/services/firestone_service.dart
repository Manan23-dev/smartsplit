import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Add expense
  Future<void> addExpense(Expense expense) async {
    if (currentUserId == null) throw Exception('User not logged in');
    
    await _firestore
        .collection('expenses')
        .doc(expense.id)
        .set(expense.toMap());
  }

  // Get user expenses stream
  Stream<List<Expense>> getUserExpenses() {
    if (currentUserId == null) return Stream.value([]);
    
    return _firestore
        .collection('expenses')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Expense.fromMap(doc.data()))
            .toList());
  }

  // Delete expense
  Future<void> deleteExpense(String expenseId) async {
    if (currentUserId == null) throw Exception('User not logged in');
    
    await _firestore
        .collection('expenses')
        .doc(expenseId)
        .delete();
  }
}