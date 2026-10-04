import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../sources/app_data_source.dart';
import '../sources/firestore_data_source.dart';
import '../models/user_model.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/session_service.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final AppDataSource _dataSource;
  final FirestoreDataSource _firestore = FirestoreDataSource();
  final SessionService _sessionService = SessionService();
  static bool _googleSignInInitialized = false;
  
  FirebaseAuth? get _firebaseAuth {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseAuth.instance;
      }
    } catch (_) {}
    return null;
  }

  AuthRepositoryImpl(this._dataSource);

  /// The single privileged email that is always treated as admin role.
  static const String _adminEmail = 'novelsdestinyadmin@gmail.com';

  bool _isAdminEmail(String email) =>
      email.trim().toLowerCase() == _adminEmail;

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
          // New Firebase user — create Firestore doc, honouring admin email
          userDoc = UserModel(
            id: fbUser.uid,
            displayName: fbUser.displayName ?? email.split('@').first,
            email: fbUser.email ?? email,
            photoUrl: fbUser.photoURL,
            role: _isAdminEmail(email) ? UserRole.admin : UserRole.reader,
            approvalStatus: ApprovalStatus.approved,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await _firestore.saveUser(userDoc);
        } else if (_isAdminEmail(email) && userDoc.role != UserRole.admin) {
          // Existing doc but role not yet set to admin — promote & persist
          userDoc = UserModel(
            id: userDoc.id,
            displayName: userDoc.displayName,
            email: userDoc.email,
            photoUrl: userDoc.photoUrl,
            role: UserRole.admin,
            approvalStatus: ApprovalStatus.approved,
            isActive: userDoc.isActive,
            createdAt: userDoc.createdAt,
            updatedAt: DateTime.now(),
            lastSeenAt: userDoc.lastSeenAt,
            bio: userDoc.bio,
          );
          await _firestore.saveUser(userDoc);
        }

        _dataSource.setCurrentUser(userDoc);
        await _sessionService.saveUserSession(userDoc);
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
      await _sessionService.saveUserSession(user);
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
      // 1. Initialize and trigger Google Sign-In flow with serverClientId on Android
      final String? envClientId = dotenv.isInitialized ? dotenv.env['GOOGLE_SERVER_CLIENT_ID'] : null;
      final String serverClientId = (envClientId != null && envClientId.isNotEmpty)
          ? envClientId
          : AppConstants.defaultGoogleServerClientId;

      final GoogleSignIn googleSignIn = GoogleSignIn.instance;

      if (!_googleSignInInitialized) {
        try {
          await googleSignIn.initialize(
            serverClientId: (!kIsWeb && io.Platform.isAndroid && serverClientId.isNotEmpty)
                ? serverClientId
                : null,
          );
          _googleSignInInitialized = true;
        } catch (_) {} // Might already be initialized
      }

      GoogleSignInAccount googleAccount;
      try {
        googleAccount = await googleSignIn.authenticate();
      } catch (e) {
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('cancel') ||
            errStr.contains('interrupted') ||
            errStr.contains('12501') ||
            errStr.contains('dismissed')) {
          throw const UnknownFailure('Google sign-in was cancelled.');
        }
        if (errStr.contains('10') ||
            errStr.contains('developer_error') ||
            errStr.contains('clientconfigurationerror') ||
            errStr.contains('28444') ||
            errStr.contains('developer console is not set up correctly')) {
          throw const ValidationFailure(
            'Google Sign-In configuration error: Missing SHA-1 fingerprint or incorrect Web Client ID in Firebase Console.',
          );
        }
        rethrow;
      }

      // 2. Get auth credentials from Google
      final GoogleSignInAuthentication googleAuth = googleAccount.authentication;
      String? accessToken;
      try {
        final authorization = await googleAccount.authorizationClient.authorizationForScopes(['email']);
        accessToken = authorization?.accessToken;
      } catch (e) {
        debugPrint('Google authorizationForScopes warning (non-fatal): $e');
      }

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
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

      // 7. Update local state and persist session
      _dataSource.updateUser(googleUser);
      _dataSource.setCurrentUser(googleUser);
      await _sessionService.saveUserSession(googleUser);

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

      // Save in memory and persist session
      _dataSource.updateUser(newUser);
      _dataSource.setCurrentUser(newUser);
      await _sessionService.saveUserSession(newUser);

      NotificationService().syncUserDeviceToken(newUser.id);
      return newUser;
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw UnknownFailure('Failed to register account: $e');
    }
  }

  @override
  Future<UserEntity?> restoreSession() async {
    try {
      // 1. Check persistent local session
      var savedUser = await _sessionService.getSavedUserSession();
      if (savedUser != null) {
        // Promote admin email in case the cached session has a stale role
        if (_isAdminEmail(savedUser.email) && savedUser.role != UserRole.admin) {
          savedUser = UserModel(
            id: savedUser.id,
            displayName: savedUser.displayName,
            email: savedUser.email,
            photoUrl: savedUser.photoUrl,
            role: UserRole.admin,
            approvalStatus: ApprovalStatus.approved,
            isActive: savedUser.isActive,
            createdAt: savedUser.createdAt,
            updatedAt: DateTime.now(),
            lastSeenAt: savedUser.lastSeenAt,
            bio: savedUser.bio,
          );
          await _sessionService.saveUserSession(savedUser);
          try { await _firestore.saveUser(savedUser); } catch (_) {}
        }
        _dataSource.updateUser(savedUser);
        _dataSource.setCurrentUser(savedUser);
        return savedUser;
      }

      // 2. Fallback to Firebase current user if available
      final fbUser = _firebaseAuth?.currentUser;
      if (fbUser != null) {
        var userDoc = await _firestore.getUser(fbUser.uid);
        // Ensure admin email always gets admin role on session restore
        if (userDoc != null && _isAdminEmail(userDoc.email) && userDoc.role != UserRole.admin) {
          userDoc = UserModel(
            id: userDoc.id,
            displayName: userDoc.displayName,
            email: userDoc.email,
            photoUrl: userDoc.photoUrl,
            role: UserRole.admin,
            approvalStatus: ApprovalStatus.approved,
            isActive: userDoc.isActive,
            createdAt: userDoc.createdAt,
            updatedAt: DateTime.now(),
            lastSeenAt: userDoc.lastSeenAt,
            bio: userDoc.bio,
          );
          await _firestore.saveUser(userDoc);
        }
        userDoc ??= UserModel(
          id: fbUser.uid,
          displayName: fbUser.displayName ?? fbUser.email?.split('@').first ?? 'User',
          email: fbUser.email ?? '',
          photoUrl: fbUser.photoURL,
          role: _isAdminEmail(fbUser.email ?? '') ? UserRole.admin : UserRole.reader,
          approvalStatus: ApprovalStatus.approved,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        _dataSource.updateUser(userDoc);
        _dataSource.setCurrentUser(userDoc);
        await _sessionService.saveUserSession(userDoc);
        return userDoc;
      }
    } catch (e) {
      debugPrint('AuthRepositoryImpl: restoreSession error: $e');
    }
    return null;
  }

  @override
  Future<void> signOut() async {
    try {
      await _sessionService.clearSession();
    } catch (e) {
      debugPrint('SessionService clearSession error: $e');
    }

    try {
      await _firebaseAuth?.signOut();
    } catch (e) {
      debugPrint('Firebase signOut error: $e');
    }

    try {
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint('GoogleSignIn signOut error: $e');
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
      await _sessionService.saveUserSession(target);
      return target;
    }

    final updated = current.copyWith(role: newRole, updatedAt: DateTime.now()) as UserModel;
    _dataSource.updateUser(updated);
    await _sessionService.saveUserSession(updated);
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
    await _sessionService.saveUserSession(updated);
    await _firestore.saveUser(updated);
    return updated;
  }
}
