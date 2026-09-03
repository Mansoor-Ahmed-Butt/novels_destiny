import 'package:uuid/uuid.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../sources/app_data_source.dart';
import '../models/user_model.dart';
import '../../core/errors/failures.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final AppDataSource _dataSource;

  AuthRepositoryImpl(this._dataSource);

  @override
  Stream<UserEntity?> authStateChanges() {
    return _dataSource.authStateStream;
  }

  @override
  UserEntity? get currentUser => _dataSource.currentUser;

  @override
  Future<UserEntity> signInWithEmailPassword(String email, String password) async {
    try {
      final allUsers = _dataSource.getAllUsers();
      final user = allUsers.firstWhere(
        (u) => u.email.toLowerCase() == email.trim().toLowerCase(),
        orElse: () => throw const NotFoundFailure('User not found with this email.'),
      );
      if (!user.isActive) {
        throw const PermissionFailure('This account is suspended. Please contact support.');
      }
      _dataSource.setCurrentUser(user);
      return user;
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw UnknownFailure('Failed to sign in: $e');
    }
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    try {
      final googleUser = UserModel(
        id: 'google_reader_${DateTime.now().millisecondsSinceEpoch}',
        displayName: 'Google Reader',
        email: 'reader.google@destiny.com',
        photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
        role: UserRole.reader,
        approvalStatus: ApprovalStatus.approved,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        bio: 'Joined via Google Sign-In.',
      );
      _dataSource.updateUser(googleUser);
      _dataSource.setCurrentUser(googleUser);
      return googleUser;
    } catch (e) {
      throw UnknownFailure('Failed to sign in with Google: $e');
    }
  }

  @override
  Future<UserEntity> signUpWithEmailPassword(
    String email,
    String password,
    String displayName,
    UserRole role,
  ) async {
    try {
      final allUsers = _dataSource.getAllUsers();
      final existing = allUsers.any((u) => u.email.toLowerCase() == email.trim().toLowerCase());
      if (existing) {
        throw const ValidationFailure('An account with this email already exists.');
      }

      final approvalStatus = role == UserRole.writer
          ? ApprovalStatus.pending
          : ApprovalStatus.approved;

      final newUser = UserModel(
        id: const Uuid().v4(),
        displayName: displayName.trim(),
        email: email.trim(),
        role: role,
        approvalStatus: approvalStatus,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        bio: role == UserRole.writer ? 'New writer applicant.' : null,
      );

      _dataSource.updateUser(newUser);
      _dataSource.setCurrentUser(newUser);
      return newUser;
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw UnknownFailure('Failed to register account: $e');
    }
  }

  @override
  Future<void> signOut() async {
    _dataSource.setCurrentUser(null);
  }

  @override
  Future<UserEntity> switchRole(UserRole newRole) async {
    final current = _dataSource.currentUser;
    if (current == null) {
      // Find default user for this role or create one
      final allUsers = _dataSource.getAllUsers();
      final target = allUsers.firstWhere((u) => u.role == newRole);
      _dataSource.setCurrentUser(target);
      return target;
    }

    final updated = current.copyWith(role: newRole, updatedAt: DateTime.now()) as UserModel;
    _dataSource.updateUser(updated);
    return updated;
  }

  @override
  Future<UserEntity> updateProfile({String? displayName, String? bio, String? photoUrl}) async {
    final current = _dataSource.currentUser;
    if (current == null) throw const UnauthorizedFailure();

    final updated = current.copyWith(
      displayName: displayName ?? current.displayName,
      bio: bio ?? current.bio,
      photoUrl: photoUrl ?? current.photoUrl,
      updatedAt: DateTime.now(),
    ) as UserModel;

    _dataSource.updateUser(updated);
    return updated;
  }
}
