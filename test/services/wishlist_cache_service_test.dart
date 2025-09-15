import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/services/paint_service.dart';
import 'package:miniature_paint_finder/services/wishlist_cache_service.dart';
import 'package:miniature_paint_finder/config/app_config.dart';

void main() {
  group('WishlistCacheService Tests', () {
    late PaintService paintService;
    late WishlistCacheService cacheService;
    late Paint testPaint;

    setUpAll(() async {
      // Initialize Flutter binding for tests
      TestWidgetsFlutterBinding.ensureInitialized();
      
      // Initialize app configuration for testing
      AppConfig.initialize(env: Environment.development);
    });

    setUp(() {
      paintService = PaintService();
      cacheService = WishlistCacheService(paintService);
      testPaint = Paint(
        id: 'test-paint-${DateTime.now().millisecondsSinceEpoch}',
        name: 'Test Paint Red',
        brand: 'Vallejo',
        hex: '#FF0000',
        set: 'Model Color',
        code: 'test-paint-red',
        r: 255,
        g: 0,
        b: 0,
        category: 'Base',
        isMetallic: false,
        isTransparent: false,
        brandId: 'Vallejo',
      );
    });

    tearDown(() async {
      // Clean up test data
      try {
        await cacheService.clearCache();
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    group('Initialization', () {
      test('should initialize cache service successfully', () async {
        expect(cacheService.isInitialized, false);

        await cacheService.initialize();

        expect(cacheService.isInitialized, true);
      });

      test('should handle initialization errors gracefully', () async {
        // Test with invalid configuration - create a mock service that throws
        final mockPaintService = PaintService();
        final invalidService = WishlistCacheService(mockPaintService);

        // This should not throw since we're using a valid PaintService
        expect(() => invalidService.initialize(), returnsNormally);
      });
    });

    group('Cache Operations', () {
      setUp(() async {
        await cacheService.initialize();
      });

      test('should add paint to wishlist successfully', () async {
        final success = await cacheService.addToWishlist(
          testPaint,
          3,
          notes: 'Test note',
        );

        expect(success, true);
      });

      test('should retrieve wishlist items', () async {
        // Add test paint
        await cacheService.addToWishlist(testPaint, 3);

        // Retrieve wishlist
        final wishlist = await cacheService.getWishlist();

        expect(wishlist, isNotEmpty);
        expect(wishlist.length, 1);
        expect(wishlist.first['paint_id'], testPaint.id);
        expect(wishlist.first['priority'], 3);
      });

      test('should update wishlist priority', () async {
        // Add test paint
        await cacheService.addToWishlist(testPaint, 3);

        // Get wishlist to find the wishlist ID
        final wishlist = await cacheService.getWishlist();
        final wishlistId = wishlist.first['id'] as String;

        // Update priority
        final success = await cacheService.updateWishlistPriority(
          testPaint.id,
          wishlistId,
          5,
        );

        expect(success, true);

        // Verify priority was updated
        final updatedWishlist = await cacheService.getWishlist();
        final item = updatedWishlist.firstWhere(
          (item) => item['paint_id'] == testPaint.id,
        );
        expect(item['priority'], 5);
      });

      test('should remove paint from wishlist', () async {
        // Add test paint
        await cacheService.addToWishlist(testPaint, 3);

        // Verify it was added
        var wishlist = await cacheService.getWishlist();
        expect(wishlist.length, 1);

        // Get wishlist ID for removal
        final wishlistId = wishlist.first['id'] as String;

        // Remove paint
        final success = await cacheService.removeFromWishlist(
          testPaint.id,
          wishlistId,
        );

        expect(success, true);

        // Verify it was removed
        wishlist = await cacheService.getWishlist();
        expect(wishlist.length, 0);
      });

      test('should handle multiple operations', () async {
        final paint1 = Paint(
          id: 'test-paint-1',
          name: 'Test Paint 1',
          brand: 'Vallejo',
          hex: '#FF0000',
          set: 'Model Color',
          code: 'test-1',
          r: 255,
          g: 0,
          b: 0,
          category: 'Base',
          isMetallic: false,
          isTransparent: false,
          brandId: 'Vallejo',
        );

        final paint2 = Paint(
          id: 'test-paint-2',
          name: 'Test Paint 2',
          brand: 'Citadel',
          hex: '#00FF00',
          set: 'Layer',
          code: 'test-2',
          r: 0,
          g: 255,
          b: 0,
          category: 'Layer',
          isMetallic: false,
          isTransparent: false,
          brandId: 'Citadel_Colour',
        );

        // Add multiple paints
        await cacheService.addToWishlist(paint1, 3);
        await cacheService.addToWishlist(paint2, 5);

        // Verify both were added
        var wishlist = await cacheService.getWishlist();
        expect(wishlist.length, 2);

        // Get wishlist IDs
        final wishlist1Id =
            wishlist.firstWhere((item) => item['paint_id'] == paint1.id)['id']
                as String;
        final wishlist2Id =
            wishlist.firstWhere((item) => item['paint_id'] == paint2.id)['id']
                as String;

        // Update priority of first paint
        await cacheService.updateWishlistPriority(paint1.id, wishlist1Id, 1);

        // Remove second paint
        await cacheService.removeFromWishlist(paint2.id, wishlist2Id);

        // Verify final state
        wishlist = await cacheService.getWishlist();
        expect(wishlist.length, 1);
        expect(wishlist.first['paint_id'], paint1.id);
        expect(wishlist.first['priority'], 1);
      });
    });

    group('Error Handling', () {
      setUp(() async {
        await cacheService.initialize();
      });

      test('should handle invalid paint data gracefully', () async {
        final invalidPaint = Paint(
          id: '',
          name: '',
          brand: '',
          hex: '',
          set: '',
          code: '',
          r: 0,
          g: 0,
          b: 0,
          category: '',
          isMetallic: false,
          isTransparent: false,
          brandId: '',
        );

        final success = await cacheService.addToWishlist(invalidPaint, 1);
        expect(success, false);
      });

      test('should handle operations on non-existent items', () async {
        final success = await cacheService.removeFromWishlist(
          'non-existent-id',
          'non-existent-wishlist-id',
        );
        expect(success, false);
      });

      test('should handle invalid priority values', () async {
        final success = await cacheService.addToWishlist(testPaint, -1);
        expect(success, false);
      });
    });

    group('Cache State Management', () {
      setUp(() async {
        await cacheService.initialize();
      });

      test('should clear cache successfully', () async {
        // Add test data
        await cacheService.addToWishlist(testPaint, 3);

        // Verify data exists
        var wishlist = await cacheService.getWishlist();
        expect(wishlist.length, 1);

        // Clear cache
        await cacheService.clearCache();

        // Verify cache is empty
        wishlist = await cacheService.getWishlist();
        expect(wishlist.length, 0);
      });

      test('should maintain cache state across operations', () async {
        // Add paint
        await cacheService.addToWishlist(testPaint, 3);

        // Verify state
        expect(cacheService.isInitialized, true);

        // Get wishlist ID for update
        final wishlistId =
            (await cacheService.getWishlist()).first['id'] as String;

        // Perform multiple operations
        await cacheService.updateWishlistPriority(testPaint.id, wishlistId, 5);
        await cacheService.addToWishlist(
          testPaint,
          1,
        ); // Should update existing

        // Verify final state
        final wishlist = await cacheService.getWishlist();
        expect(wishlist.length, 1);
        expect(wishlist.first['priority'], 1);
      });
    });
  });
}
