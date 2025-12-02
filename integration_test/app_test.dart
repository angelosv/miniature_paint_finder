import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Import test setup
import 'test_setup.dart';

import 'flows/auth_flow_test.dart' as auth_tests;
import 'flows/project_flow_test.dart' as project_tests;
import 'flows/palette_flow_test.dart' as palette_tests;
import 'flows/inventory_flow_test.dart' as inventory_tests;
import 'flows/wishlist_flow_test.dart' as wishlist_tests;
import 'flows/offline_flow_test.dart' as offline_tests;
import 'flows/navigation_flow_test.dart' as navigation_tests;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Configurar entorno de testing
  setUpAll(() async {
    await TestSetup.setupTestEnvironment();
  });

  tearDownAll(() async {
    await TestSetup.tearDownTestEnvironment();
  });

  group('🧪 Miniature Paint Finder - Complete E2E Test Suite', () {
    
    // 🔐 Authentication Tests
    group('Authentication Flow', () {
      auth_tests.main();
    });

    // 📱 Navigation Tests  
    group('Navigation Flow', () {
      navigation_tests.main();
    });

    // 🎨 Project Management Tests
    group('Project Management', () {
      project_tests.main();
    });

    // 🎭 Palette Management Tests
    group('Palette Management', () {
      palette_tests.main();
    });

    // 📦 Inventory Management Tests
    group('Inventory Management', () {
      inventory_tests.main();
    });

    // ❤️ Wishlist Management Tests
    group('Wishlist Management', () {
      wishlist_tests.main();
    });

    // 📱 Offline Functionality Tests
    group('Offline Functionality', () {
      offline_tests.main();
    });
  });
}
