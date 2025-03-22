/// Base abstract repository interface to enforce consistent patterns
/// for all repository implementations
abstract class BaseRepository<T> {
  /// Get all items
  Future<List<T>> getAll();

  /// Get item by id
  Future<T?> getById(String id);

  /// Create a new item
  Future<T> create(T item);

  /// Update an existing item
  Future<T> update(T item);

  /// Delete an item by id
  Future<bool> delete(String id);
}
