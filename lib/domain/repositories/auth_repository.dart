import '../entities/user_entity.dart';

abstract class IAuthRepository {
  Stream<UserEntity?> authStateChanges();
  UserEntity? get currentUser;
  Future<UserEntity> signInWithEmailPassword(String email, String password);
  Future<UserEntity> signUpWithEmailPassword(String email, String password, String displayName, UserRole role);
  Future<void> signOut();
  Future<UserEntity> switchRole(UserRole newRole);
  Future<UserEntity> updateProfile({String? displayName, String? bio, String? photoUrl});
}
