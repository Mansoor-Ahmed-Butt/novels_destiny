import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class AuthUseCases {
  final IAuthRepository _authRepository;

  AuthUseCases(this._authRepository);

  UserEntity? get currentUser => _authRepository.currentUser;
  Stream<UserEntity?> authStateChanges() => _authRepository.authStateChanges();

  Future<UserEntity> signIn(String email, String password) =>
      _authRepository.signInWithEmailPassword(email, password);

  Future<UserEntity> signUp(String email, String password, String displayName, UserRole role) =>
      _authRepository.signUpWithEmailPassword(email, password, displayName, role);

  Future<void> signOut() => _authRepository.signOut();

  Future<UserEntity> switchRole(UserRole newRole) => _authRepository.switchRole(newRole);

  Future<UserEntity> updateProfile({String? displayName, String? bio, String? photoUrl}) =>
      _authRepository.updateProfile(displayName: displayName, bio: bio, photoUrl: photoUrl);
}
