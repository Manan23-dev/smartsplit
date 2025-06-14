import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isAuthenticated) {
          // Start listening to expenses when user is authenticated
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<ExpenseProvider>().listenToExpenses();
          });
          
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}