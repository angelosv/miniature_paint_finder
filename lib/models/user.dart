import 'package:flutter/material.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String? profileImage;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final Map<String, dynamic>? preferences;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.profileImage,
    required this.createdAt,
    this.lastLoginAt,
    this.preferences,
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
    };
  }

  // Demo user for development and testing
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
  );
}
