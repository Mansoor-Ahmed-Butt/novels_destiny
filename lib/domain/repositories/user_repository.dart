import '../entities/user_entity.dart';

abstract class IUserRepository {
  Future<List<UserEntity>> getAllUsers();
  Future<UserEntity?> getUserById(String id);
  Future<void> updateUserStatus(String id, bool isActive);
}
