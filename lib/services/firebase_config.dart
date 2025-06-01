import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  static Future<void> init() async {
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyDO9f1l9fuv5kSzwmvfZkn2LJcfqRWD35U",
          appId: "1:377740311156:ios:e2049f0d3e0389ee09af21",
          messagingSenderId: "377740311156",
          projectId: "paints-78769",
          storageBucket: "paints-78769.firebasestorage.app",
          iosClientId:
              "377740311156-n4o2p58h1plht8ajofq9p1b45epq1ndq.apps.googleusercontent.com",
          iosBundleId: "com.angelosv.miniaturePaintFinder",
        ),
      );
    } catch (e, stackTrace) {
      rethrow;
    }
  }
}
