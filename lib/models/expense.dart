import 'package:uuid/uuid.dart';

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
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.millisecondsSinceEpoch,
      'category': category,
      'userId': userId,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
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