import 'package:fletch/core/contracts/repository.dart';
import 'package:fletch/backend/workspace/models/workspace.dart';
import 'package:fletch/backend/collections/models/collection.dart';
import 'package:fletch/backend/collections/repository/collection_repository.dart';

class DeleteWorkspace {
  final IRepository<WorkspaceModel> _workspaceRepository;
  final IRepository<RequestCollection> _collectionRepository;

  DeleteWorkspace({
    required IRepository<WorkspaceModel> workspaceRepository,
    required IRepository<RequestCollection> collectionRepository,
  })  : _workspaceRepository = workspaceRepository,
        _collectionRepository = collectionRepository;

  Future<void> call(String workspaceId) async {
    await _workspaceRepository.delete(workspaceId);
    if (_collectionRepository is CollectionRepository) {
      await _collectionRepository.deleteAll(workspaceId);
    }
  }
}
