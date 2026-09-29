import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current Firebase user
  User? get currentUser => _auth.currentUser;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign Up with Email and Password
  Future<UserModel> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // 1. Create Firebase Auth user
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final User? user = credential.user;
      if (user == null) {
        throw Exception('User creation failed.');
      }

      // Update Firebase Auth Display Name
      await user.updateDisplayName(name.trim());

      // 2. Create User Model
      UserModel newUser = UserModel(
        uid: user.uid,
        email: email.trim(),
        displayName: name.trim(),
        createdAt: DateTime.now(),
      );

      // 3. Save User to Firestore collection 'users'
      await _firestore.collection('users').doc(user.uid).set(newUser.toMap());

      return newUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to sign up: ${e.toString()}');
    }
  }

  // Sign In with Email and Password
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final User? user = credential.user;
      if (user == null) {
        throw Exception('Sign in failed.');
      }

      // Fetch user profile from Firestore
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(
          Map<String, dynamic>.from(doc.data() as Map),
          doc.id,
        );
      } else {
        // Fallback user model if document doesn't exist
        return UserModel(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? 'User',
          createdAt: DateTime.now(),
        );
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to sign in: ${e.toString()}');
    }
  }

  // Fetch Current User Details from Firestore
  Future<UserModel?> getUserDetails(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(
          Map<String, dynamic>.from(doc.data() as Map),
          doc.id,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Custom User-Friendly Exception Handler
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'weak-password':
        return 'The password is too weak. Choose at least 6 characters.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}
