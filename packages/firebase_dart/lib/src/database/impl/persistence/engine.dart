import 'package:firebase_dart/src/database/impl/operations/tree.dart';
import 'package:firebase_dart/src/database/impl/persistence/prune_forest.dart';
import 'package:firebase_dart/src/database/impl/persistence/tracked_query.dart';
import 'package:firebase_dart/src/database/impl/tree.dart';

import '../data_observer.dart';
import '../treestructureddata.dart';

/// This class provides an interface to a persistent cache.
///
/// The persistence cache persists user writes, cached server data and the
/// corresponding completeness tree.
///
/// There exists one PersistentCache per repo.
abstract class PersistenceStorageEngine {
  /// Save a user operation
  void saveUserOperation(TreeOperation operation, int writeId);

  /// Remove a write with the given write id.
  void removeUserOperation(int writeId);

  /// Loads all data at a path.
  ///
  /// It has no knowledge of whether the data is "complete" or not.
  IncompleteData serverCache(Path<Name> path);

  /// Return all writes that were persisted
  Map<int, TreeOperation> loadUserOperations();

  /// Overwrite the server cache at the given path with the given node.
  void overwriteServerCache(TreeOperation operation);

  int serverCacheEstimatedSizeInBytes();

  void saveTrackedQuery(TrackedQuery trackedQuery);

  void deleteTrackedQuery(int trackedQueryId);

  List<TrackedQuery> loadTrackedQueries();

  void resetPreviouslyActiveTrackedQueries(DateTime lastUse);

  void pruneCache(PruneForest pruneForest);

  void beginTransaction();

  void endTransaction();

  void setTransactionSuccessful();

  Future<void> close();
}
