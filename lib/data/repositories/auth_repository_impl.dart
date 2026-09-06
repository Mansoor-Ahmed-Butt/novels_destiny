import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
      // 1. Initialize and trigger Google Sign-In flow
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;
      try {
        await googleSignIn.initialize();
      } catch (_) {} // Might already be initialized

      GoogleSignInAccount googleAccount;
      try {
        googleAccount = await googleSignIn.authenticate();
      } catch (e) {
        if (e.toString().contains('canceled') || e.toString().contains('interrupted')) {
          throw const UnknownFailure('Google sign-in was cancelled.');
        }
        rethrow;
      }

      // 2. Get auth credentials from Google
      final GoogleSignInAuthentication googleAuth = googleAccount.authentication;
      final authorization = await googleAccount.authorizationClient.authorizationForScopes([]);
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: authorization?.accessToken,
        idToken: googleAuth.idToken,
      );

      // 3. Sign in to Firebase with Google credential
      UserCredential? firebaseCredential;
      try {
        firebaseCredential = await _firebaseAuth?.signInWithCredential(credential);
      } catch (e) {
        debugPrint('Firebase Auth Google signIn failed: $e');
      }

      // 4. Build UserModel from Firebase user or Google account info
      final String uid = firebaseCredential?.user?.uid ?? 'google_${googleAccount.id}';
      final String displayName = firebaseCredential?.user?.displayName
          ?? googleAccount.displayName
          ?? googleAccount.email.split('@').first;
      final String email = firebaseCredential?.user?.email ?? googleAccount.email;
      final String? photoUrl = firebaseCredential?.user?.photoURL ?? googleAccount.photoUrl;

      // 5. Check if user already exists in Firestore
      UserModel? existingUser;
      try {
        existingUser = await _firestore.getUser(uid).timeout(
          const Duration(seconds: 5),
          onTimeout: () => null,
        );
      } catch (e) {
        debugPrint('Firestore getUser warning during Google sign-in: $e');
      }

      final UserModel googleUser;
      if (existingUser != null) {
        googleUser = existingUser;
      } else {
        googleUser = UserModel(
          id: uid,
          displayName: displayName,
          email: email,
          photoUrl: photoUrl,
          role: UserRole.reader,
          approvalStatus: ApprovalStatus.approved,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          bio: 'Joined via Google Sign-In.',
        );

        // 6. Save to Firestore with a timeout so we never hang
        try {
          await _firestore.saveUser(googleUser).timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint('Firestore saveUser timed out during Google sign-in, continuing anyway.');
            },
          );
        } catch (e) {
          debugPrint('Firestore saveUser warning during Google sign-in: $e');
        }
      }

      // 7. Update local state and proceed
      _dataSource.updateUser(googleUser);
      _dataSource.setCurrentUser(googleUser);

      try {
        NotificationService().syncUserDeviceToken(googleUser.id);
      } catch (_) {}

      return googleUser;
    } catch (e) {
      if (e is AppFailure) rethrow;
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
