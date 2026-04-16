import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

/// Exposes Firebase auth state to the widget tree via Provider.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isInitialized = false;

  AuthProvider() {
    // Listen to Firebase auth state — fires immediately with current user
    _authService.authStateChanges.listen((user) {
      _user = user;
      _isInitialized = true;
      notifyListeners();
    });
  }

  // ── Getters ───────────────────────────────────────────────────────
  User? get user => _user;
  bool get isLoggedIn => _user != null;

  /// True once Firebase has confirmed the initial auth state.
  bool get isInitialized => _isInitialized;

  /// Display name shown in the dashboard header.
  String get displayName =>
      _user?.displayName ??
      (_user?.email?.split('@')[0] ?? 'Student');

  // ── Actions ───────────────────────────────────────────────────────

  /// Returns an error string on failure, null on success.
  Future<String?> signIn(String email, String password) async {
    try {
      await _authService.signInWithEmail(email, password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _authService.getErrorMessage(e.code);
    } catch (e) {
      return 'Generic Error: ${e.toString()}';
    }
  }

  /// Returns an error string on failure, null on success.
  Future<String?> register(
      String email, String password, String name) async {
    try {
      await _authService.registerWithEmail(email, password, name);
      return null;
    } on FirebaseAuthException catch (e) {
      return _authService.getErrorMessage(e.code);
    } catch (e) {
      return 'Generic Error: ${e.toString()}';
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }
}
