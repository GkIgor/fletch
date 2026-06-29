abstract class IRepository<T> {
  Future<T?> getById(String id);
  Future<void> save(T item);
  Future<void> delete(String id);
}
