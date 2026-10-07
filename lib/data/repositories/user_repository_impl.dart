import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository.dart';
import '../sources/app_data_source.dart';
import '../sources/firestore_data_source.dart';
import '../models/user_model.dart';
import '../../core/errors/failures.dart';

class UserRepositoryImpl implements IUserRepository {
  final AppDataSource _dataSource;
  final FirestoreDataSource _firestore = FirestoreDataSource();

  UserRepositoryImpl(this._dataSource);

  @override
  Future<List<UserEntity>> getAllUsers() async {
    try {
      // Fetch all users from Firestore (real data)
      final remote = await _firestore.getAllUsers();
      for (final user in remote) {
        _dataSource.updateUser(user);
      }
      return remote;
    } catch (e) {
      throw UnknownFailure('Failed to list users: $e');
    }
  }

  @override
  Future<UserEntity?> getUserById(String id) async {
    try {
      // Check local cache first
      final local = _dataSource.getUserById(id);
      if (local != null) return local;
      // Fallback to Firestore
      return await _firestore.getUser(id);
    } catch (e) {
      throw UnknownFailure('Failed to load user: $e');
    }
  }

  @override
  Future<void> updateUserStatus(String id, bool isActive) async {
    try {
      final user = _dataSource.getUserById(id) ?? await _firestore.getUser(id);
      if (user != null) {
        final updated = user.copyWith(isActive: isActive, updatedAt: DateTime.now()) as UserModel;
        _dataSource.updateUser(updated);
        await _firestore.saveUser(updated);
      }
    } catch (e) {
      throw UnknownFailure('Failed to update user status: $e');
    }
  }

  @override
  Future<List<UserEntity>> getPendingWriters() async {
    try {
      // Fetch all users and filter pending writers
      final remote = await _firestore.getAllUsers();
      for (final user in remote) {
        _dataSource.updateUser(user);
      }
      return remote
          .where((u) => u.role == UserRole.writer && u.approvalStatus == ApprovalStatus.pending)
          .toList();
    } catch (e) {
      // Fallback to in-memory
      return _dataSource.getPendingWriters();
    }
  }

  @override
  Future<void> approveWriter(String id) async {
    try {
      _dataSource.approveWriter(id);
      await _firestore.updateUserApprovalStatus(id, ApprovalStatus.approved.name);
    } catch (e) {
      throw UnknownFailure('Failed to approve writer: $e');
    }
  }

  @override
  Future<void> rejectWriter(String id) async {
    try {
      _dataSource.rejectWriter(id);
      await _firestore.updateUserApprovalStatus(id, ApprovalStatus.rejected.name);
    } catch (e) {
      throw UnknownFailure('Failed to reject writer: $e');
    }
  }
}
