import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

// This class will be used to initialize Firebase
class FirebaseService {
  static Future<void> initializeFirebase() async {
    try {
      await Firebase.initializeApp();
    } catch (e) {}
  }
}
