import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'lib/models/paint.dart';
import 'lib/services/paint_service.dart';
import 'lib/services/wishlist_cache_service.dart';

/// Test manual para wishlist
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🧪 Starting wishlist test...');

  // Test 1: Direct PaintService test
  await testDirectPaintService();

  // Test 2: WishlistCacheService test
  await testWishlistCacheService();
}

Future<void> testDirectPaintService() async {
  print('\n📱 Testing direct PaintService...');

  try {
    final paintService = PaintService();

    // Create a test paint
    final testPaint = Paint(
      id: 'test-paint-123',
      name: 'Test Paint Red',
      brand: 'Vallejo',
      hex: '#FF0000',
      set: 'Model Color',
      code: 'test-paint-123',
      r: 255,
      g: 0,
      b: 0,
      category: 'Base',
      isMetallic: false,
      isTransparent: false,
      brandId: 'Vallejo',
    );

    print('🎨 Test paint created: ${testPaint.name}');

    // Try to add to wishlist directly
    final result = await paintService.addToWishlistDirect(
      testPaint,
      3, // Priority
      'test-user-id',
    );

    print('📊 Direct service result:');
    print('  - Success: ${result['success']}');
    print('  - Message: ${result['message']}');
    print('  - Response: ${result['response']}');

    if (result['success'] != true) {
      print('❌ Direct service failed!');
    } else {
      print('✅ Direct service succeeded!');
    }
  } catch (e) {
    print('❌ Direct service test failed with exception: $e');
  }
}

Future<void> testWishlistCacheService() async {
  print('\n🗂️ Testing WishlistCacheService...');

  try {
    final paintService = PaintService();
    final cacheService = WishlistCacheService(paintService);

    print('🔧 Initializing cache service...');
    await cacheService.initialize();

    if (!cacheService.isInitialized) {
      print('❌ Cache service failed to initialize');
      return;
    }

    print('✅ Cache service initialized');
    cacheService.debugCacheState();

    // Create a test paint
    final testPaint = Paint(
      id: 'cache-test-paint-456',
      name: 'Cache Test Paint Blue',
      brand: 'Citadel',
      hex: '#0000FF',
      set: 'Layer',
      code: 'cache-test-paint-456',
      r: 0,
      g: 0,
      b: 255,
      category: 'Layer',
      isMetallic: false,
      isTransparent: false,
      brandId: 'Citadel_Colour',
    );

    print('🎨 Test paint created: ${testPaint.name}');

    // Try to add to wishlist via cache service
    final success = await cacheService.addToWishlist(
      testPaint,
      4, // Priority
      notes: 'Test note from cache service',
    );

    print('📊 Cache service result: $success');

    if (success) {
      print('✅ Cache service add succeeded!');

      // Debug state after add
      print('\n🔍 Cache state after add:');
      cacheService.debugCacheState();

      // Try to force sync
      print('\n🔄 Forcing sync...');
      await cacheService.forceSync();

      // Debug state after sync
      print('\n🔍 Cache state after sync:');
      cacheService.debugCacheState();
    } else {
      print('❌ Cache service add failed!');
    }
  } catch (e) {
    print('❌ Cache service test failed with exception: $e');
  }
}
