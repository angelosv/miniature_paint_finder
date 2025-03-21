import 'dart:async';
import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/models/user.dart';

// This service will handle authentication related operations
class AuthService {
  // Singleton instance
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Stream controller for auth state changes
  final StreamController<User?> _authStateController =
      StreamController<User?>.broadcast();
  Stream<User?> get authStateChanges => _authStateController.stream;

  // Current user
  User? _currentUser;
  User? get currentUser => _currentUser;

  // Initialize auth service - set initial user state
  Future<void> init() async {
    // Check for stored credentials
    // In real app, this would check secure storage
    await Future.delayed(const Duration(milliseconds: 500));

    // For demo, we'll start with no user logged in
    _currentUser = null;
    _authStateController.add(_currentUser);
  }

  // Sign in with email and password
  Future<User> signInWithEmailPassword(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // In real app, this would make an API call
    // For demo, we'll always return success with the demo user
    _currentUser = User.demoUser;
    _authStateController.add(_currentUser);

    return _currentUser!;
  }

  // Sign up with email, password and name
  Future<User> signUpWithEmailPassword(
    String email,
    String password,
    String name,
  ) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // In real app, this would make an API call
    // For demo, we'll always return success with the demo user
    final newUser = User(
      id: 'new-user-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );

    _currentUser = newUser;
    _authStateController.add(_currentUser);

    return _currentUser!;
  }

  // Sign out
  Future<void> signOut() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // In real app, this would clear tokens, etc.
    _currentUser = null;
    _authStateController.add(_currentUser);
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // In real app, this would trigger a password reset email
    // For demo, we just return success
    return;
  }

  // Dispose resources
  void dispose() {
    _authStateController.close();
  }
}
