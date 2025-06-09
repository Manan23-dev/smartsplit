import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    // Listen to auth state changes
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final error = await _authService.signInWithEmailAndPassword(email, password);
    
    _isLoading = false;
    if (error != null) {
      _errorMessage = error;
    }
    notifyListeners();
    
    return error == null;
  }

  Future<bool> signUp(String email, String password, String displayName) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final error = await _authService.createUserWithEmailAndPassword(email, password, displayName);
    
    _isLoading = false;
    if (error != null) {
      _errorMessage = error;
    }
    notifyListeners();
    
    return error == null;
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }
}