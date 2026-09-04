import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../sources/app_data_source.dart';
import '../sources/firestore_data_source.dart';
import '../models/user_model.dart';
import '../../core/errors/failures.dart';
import '../../core/services/notification_service.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final AppDataSource _dataSource;
  final FirestoreDataSource _firestore = FirestoreDataSource();
  
  FirebaseAuth? get _firebaseAuth {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseAuth.instance;
      }
    } catch (_) {}
    return null;
  }

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
      // 1. Attempt real Firebase Auth
      UserCredential? credential;
      try {
        credential = await _firebaseAuth?.signInWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );
      } catch (e) {
        debugPrint('Firebase Auth signIn failed, checking demo credentials: $e');
      }

      if (credential?.user != null) {
        final fbUser = credential!.user!;
        var userDoc = await _firestore.getUser(fbUser.uid);
        if (userDoc == null) {
          userDoc = UserModel(
            id: fbUser.uid,
            displayName: fbUser.displayName ?? email.split('@').first,
            email: fbUser.email ?? email,
            photoUrl: fbUser.photoURL,
            role: UserRole.reader,
            approvalStatus: ApprovalStatus.approved,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await _firestore.saveUser(userDoc);
        }

        _dataSource.setCurrentUser(userDoc);
        NotificationService().syncUserDeviceToken(userDoc.id);
        return userDoc;
      }

      // 2. Demo accounts fallback
      final allUsers = _dataSource.getAllUsers();
      final user = allUsers.firstWhere(
        (u) => u.email.toLowerCase() == email.trim().toLowerCase(),
        orElse: () => throw const NotFoundFailure('Invalid email or password. Please check your credentials.'),
      );
      if (!user.isActive) {
        throw const PermissionFailure('This account is suspended. Please contact support.');
      }
      _dataSource.setCurrentUser(user);
      NotificationService().syncUserDeviceToken(user.id);
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

      await _firestore.saveUser(googleUser);
      _dataSource.updateUser(googleUser);
      _dataSource.setCurrentUser(googleUser);
      NotificationService().syncUserDeviceToken(googleUser.id);
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
      final approvalStatus = role == UserRole.writer
          ? ApprovalStatus.pending
          : ApprovalStatus.approved;

      String uid = const Uuid().v4();

      // Attempt Firebase Auth sign-up
      try {
        final cred = await _firebaseAuth?.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );
        if (cred?.user != null) {
          uid = cred!.user!.uid;
          await cred.user!.updateDisplayName(displayName.trim());
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          throw const ValidationFailure('An account with this email already exists.');
        } else if (e.code == 'weak-password') {
          throw const ValidationFailure('Password is too weak. Please use at least 6 characters.');
        }
        debugPrint('Firebase createUser warning: ${e.message}');
      } catch (e) {
        debugPrint('Firebase Auth sign up error: $e');
      }

      final newUser = UserModel(
        id: uid,
        displayName: displayName.trim(),
        email: email.trim(),
        role: role,
        approvalStatus: approvalStatus,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        bio: role == UserRole.writer ? 'New writer applicant.' : null,
      );

      // Save in Firestore
      await _firestore.saveUser(newUser);

      // Save in memory
      _dataSource.updateUser(newUser);
      _dataSource.setCurrentUser(newUser);

      NotificationService().syncUserDeviceToken(newUser.id);
      return newUser;
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw UnknownFailure('Failed to register account: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth?.signOut();
    } catch (e) {
      debugPrint('Firebase signOut error: $e');
    }
    _dataSource.setCurrentUser(null);
  }

  @override
  Future<UserEntity> switchRole(UserRole newRole) async {
    final current = _dataSource.currentUser;
    if (current == null) {
      final allUsers = _dataSource.getAllUsers();
      final target = allUsers.firstWhere((u) => u.role == newRole);
      _dataSource.setCurrentUser(target);
      return target;
    }

    final updated = current.copyWith(role: newRole, updatedAt: DateTime.now()) as UserModel;
    _dataSource.updateUser(updated);
    await _firestore.saveUser(updated);
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
    await _firestore.saveUser(updated);
    return updated;
  }
}
