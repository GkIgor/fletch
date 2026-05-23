import 'package:fletch/repository/collection_repository.dart';
import 'package:fletch/repository/workspace_repository.dart';

class WorkspaceService {
  final WorkspaceRepository _wsRepository = WorkspaceRepository();
  final CollectionRepository _collectionRepository = CollectionRepository();

  Future<void> removeWorkspace(String ws) async {
    await _wsRepository.delete(ws);
    await _collectionRepository.deleteAll(ws);
  }
}
