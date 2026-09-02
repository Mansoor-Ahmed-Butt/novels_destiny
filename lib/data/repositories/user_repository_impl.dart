import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository.dart';
import '../sources/app_data_source.dart';
import '../models/user_model.dart';
import '../../core/errors/failures.dart';

class UserRepositoryImpl implements IUserRepository {
  final AppDataSource _dataSource;

  UserRepositoryImpl(this._dataSource);

  @override
  Future<List<UserEntity>> getAllUsers() async {
    try {
      return _dataSource.getAllUsers();
    } catch (e) {
      throw UnknownFailure('Failed to list users: $e');
    }
  }

  @override
  Future<UserEntity?> getUserById(String id) async {
    try {
      return _dataSource.getUserById(id);
    } catch (e) {
      throw UnknownFailure('Failed to load user: $e');
    }
  }

  @override
  Future<void> updateUserStatus(String id, bool isActive) async {
    try {
      final user = _dataSource.getUserById(id);
      if (user != null) {
        _dataSource.updateUser(user.copyWith(isActive: isActive, updatedAt: DateTime.now()) as UserModel);
      }
    } catch (e) {
      throw UnknownFailure('Failed to update user status: $e');
    }
  }
}
