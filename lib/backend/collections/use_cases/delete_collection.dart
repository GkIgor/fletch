import 'package:fletch/core/contracts/repository.dart';
import 'package:fletch/backend/collections/models/collection.dart';

class DeleteCollection {
  final IRepository<RequestCollection> _collectionRepository;

  DeleteCollection({
    required IRepository<RequestCollection> collectionRepository,
  }) : _collectionRepository = collectionRepository;

  Future<void> call(String collectionId) async {
    await _collectionRepository.delete(collectionId);
  }
}
