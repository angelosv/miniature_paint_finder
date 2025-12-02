import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:miniature_paint_finder/services/inventory_cache_service.dart';
import 'package:miniature_paint_finder/services/inventory_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Generate mocks
@GenerateMocks([InventoryService])
import 'inventory_cache_service_test.mocks.dart';

void main() {
  late InventoryCacheService inventoryCacheService;
  late MockInventoryService mockInventoryService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockInventoryService = MockInventoryService();
    inventoryCacheService = InventoryCacheService(mockInventoryService);
  });

  group('InventoryCacheService Sync', () {
    test('should call updateInventoryRecord when processing update operation', () async {
      // Arrange
      final operation = {
        'type': 'update',
        'inventoryId': 'test_inv_id',
        'quantity': 5,
        'notes': 'updated notes',
        'timestamp': DateTime.now().toIso8601String(),
        'id': 'op_id_1',
      };

      // Mock successful update
      when(mockInventoryService.updateInventoryRecord(any, any, any))
          .thenAnswer((_) async => true);

      // Mock loadInventoryFromApi to avoid MissingStubError during sync
      when(mockInventoryService.loadInventoryFromApi(
        limit: anyNamed('limit'),
        page: anyNamed('page'),
        searchQuery: anyNamed('searchQuery'),
        onlyInStock: anyNamed('onlyInStock'),
        brand: anyNamed('brand'),
        category: anyNamed('category'),
        minStock: anyNamed('minStock'),
        maxStock: anyNamed('maxStock'),
      )).thenAnswer((_) async => {'inventories': [], 'totalPages': 1});
      
      // We need to inject the operation into the pending operations list
      // Since we can't access private members, we'll use the public updateInventoryItem method
      // which adds to the queue and triggers sync if connected.
      
      // Act
      await inventoryCacheService.updateInventoryItem('test_inv_id', 5, notes: 'updated notes');
      
      // Wait for async operations to complete (sync is triggered in background)
      await Future.delayed(Duration(milliseconds: 100));

      // Assert
      verify(mockInventoryService.updateInventoryRecord('test_inv_id', 5, 'updated notes')).called(1);
    });
  });
}
