import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;
  
  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<String?> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Sign in failed';
    } catch (e) {
      return 'An unexpected error occurred';
    }
  }

  // Create user with email and password
  Future<String?> createUserWithEmailAndPassword(String email, String password, String displayName) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        // Create user document in Firestore
        final appUser = AppUser(
          id: credential.user!.uid,
          email: email,
          displayName: displayName,
          createdAt: DateTime.now(),
        );
        
        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(appUser.toMap());
      }
      
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Account creation failed';
    } catch (e) {
      return 'An unexpected error occurred';
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}