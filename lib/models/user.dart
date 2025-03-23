import 'package:flutter/material.dart';

/// Model representing a user in the application
class User {
  /// Unique identifier for the user
  final String id;

  /// User's display name
  final String name;

  /// User's email address
  final String email;

  /// URL to user's profile image (optional)
  final String? profileImage;

  /// When the user account was created
  final DateTime createdAt;

  /// When the user last logged in (optional)
  final DateTime? lastLoginAt;

  /// User preferences stored as key-value pairs
  final Map<String, dynamic>? preferences;

  /// Authentication provider (email, google, apple, etc.)
  final String authProvider;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.profileImage,
    required this.createdAt,
    this.lastLoginAt,
    this.preferences,
    required this.authProvider,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      profileImage: json['profile_image'],
      createdAt: DateTime.parse(json['created_at']),
      lastLoginAt:
          json['last_login_at'] != null
              ? DateTime.parse(json['last_login_at'])
              : null,
      preferences: json['preferences'],
      authProvider: json['auth_provider'] ?? 'email',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profile_image': profileImage,
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'preferences': preferences,
      'auth_provider': authProvider,
    };
  }

  /// Demo user for development and testing
  static User demoUser = User(
    id: 'demo-user-001',
    name: 'Demo Painter',
    email: 'demo@miniaturepaintfinder.com',
    profileImage: null,
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
    lastLoginAt: DateTime.now(),
    preferences: {
      'theme': 'dark',
      'notifications_enabled': true,
      'favorite_brands': ['Citadel', 'Vallejo', 'Army Painter'],
    },
    authProvider: 'email',
  );
}
