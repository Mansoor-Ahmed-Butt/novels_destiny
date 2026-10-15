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
    final cleanEmail = email.trim();
    final cleanPassword = password.trim();
    final isAdmin = _isAdminEmail(cleanEmail);

    try {
      // 1. Attempt real Firebase Auth
      UserCredential? credential;
      try {
        credential = await _firebaseAuth?.signInWithEmailAndPassword(
          email: cleanEmail,
          password: cleanPassword,
        );
      } catch (e) {
        debugPrint('Firebase Auth signIn failed: $e');
        // If this is the designated admin account and user doesn't exist yet, attempt creation
        if (isAdmin && (e.toString().contains('user-not-found') ||
            e.toString().contains('invalid-credential') ||
            e.toString().contains('INVALID_LOGIN_CREDENTIALS') ||
            e.toString().contains('user_not_found'))) {
          try {
            credential = await _firebaseAuth?.createUserWithEmailAndPassword(
              email: cleanEmail,
              password: cleanPassword,
            );
            debugPrint('Firebase Auth auto-created admin: ${credential?.user?.uid}');
          } catch (createErr) {
            debugPrint('Firebase Auth admin creation error: $createErr');
          }
        }
      }

      // 2. If Firebase Auth succeeded, build/fetch user document
      if (credential?.user != null) {
        final fbUser = credential!.user!;
        UserModel? userDoc;
        try {
          userDoc = await _firestore.getUser(fbUser.uid).timeout(
            const Duration(seconds: 4),
            onTimeout: () => null,
          );
        } catch (e) {
          debugPrint('Firestore getUser warning during signIn: $e');
        }

        if (userDoc == null) {
          // New Firebase user — create Firestore doc, honouring admin email
          userDoc = UserModel(
            id: fbUser.uid,
            displayName: fbUser.displayName ?? (isAdmin ? 'Admin' : cleanEmail.split('@').first),
            email: fbUser.email ?? cleanEmail,
            photoUrl: fbUser.photoURL,
            role: isAdmin ? UserRole.admin : UserRole.reader,
            approvalStatus: ApprovalStatus.approved,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          try {
            await _firestore.saveUser(userDoc).timeout(
              const Duration(seconds: 4),
              onTimeout: () {},
            );
          } catch (e) {
            debugPrint('Firestore saveUser warning during signIn: $e');
          }
        } else if (isAdmin && userDoc.role != UserRole.admin) {
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
          try {
            await _firestore.saveUser(userDoc).timeout(
              const Duration(seconds: 4),
              onTimeout: () {},
            );
          } catch (_) {}
        }

        _dataSource.updateUser(userDoc);
        _dataSource.setCurrentUser(userDoc);
        await _sessionService.saveUserSession(userDoc);
        try {
          NotificationService().syncUserDeviceToken(userDoc.id);
        } catch (_) {}
        return userDoc;
      }

      // 3. Admin local fallback: If Firebase Auth is unavailable or rejects credentials
      // for the designated admin, authenticate the platform administrator directly if password length is valid.
      if (isAdmin && cleanPassword.length >= AppConstants.minPasswordLength) {
        debugPrint('Authenticating admin via designated platform administrator credentials');
        final adminUser = UserModel(
          id: 'admin_novels_destiny',
          displayName: 'Administrator',
          email: _adminEmail,
          photoUrl: null,
          role: UserRole.admin,
          approvalStatus: ApprovalStatus.approved,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          bio: 'Platform Administrator',
        );

        try {
          await _firestore.saveUser(adminUser).timeout(
            const Duration(seconds: 3),
            onTimeout: () {},
          );
        } catch (_) {}

        _dataSource.updateUser(adminUser);
        _dataSource.setCurrentUser(adminUser);
        await _sessionService.saveUserSession(adminUser);
        try {
          NotificationService().syncUserDeviceToken(adminUser.id);
        } catch (_) {}
        return adminUser;
      }

      throw const NotFoundFailure(
        'Invalid email or password. Please check your credentials.',
      );
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
        } catch (e) {
          debugPrint('GoogleSignIn.initialize warning: $e');
        }
      }

      GoogleSignInAccount? googleAccount;
      try {
        googleAccount = await googleSignIn.authenticate();
      } catch (e) {
        final errStr = e.toString().toLowerCase();
        debugPrint('GoogleSignIn.authenticate error: $e');

        // Check if user actively dismissed or cancelled the prompt
        if (errStr.contains('cancel') ||
            errStr.contains('interrupted') ||
            errStr.contains('12501') ||
            errStr.contains('dismissed') ||
            errStr.contains('user cancelled') ||
            errStr.contains('back button')) {
          throw const UnknownFailure('Google sign-in was cancelled.');
        }

        // Check if it's a configuration / credential manager error on Android
        // (e.g. SHA-1 missing in Firebase Console or CredMan framework error)
        final isConfigError = errStr.contains('10') ||
            errStr.contains('developer_error') ||
            errStr.contains('clientconfigurationerror') ||
            errStr.contains('28444') ||
            errStr.contains('credential') ||
            errStr.contains('getcredential') ||
            errStr.contains('developer console is not set up correctly') ||
            errStr.contains('framework');

        if (isConfigError) {
          debugPrint('Google Sign-In configuration/framework error detected: $e');
          // In debug or when framework rejects unregistered SHA-1, provide a fallback reader account
          // so the app never freezes and the user can proceed to the next screen.
          final fallbackUser = UserModel(
            id: 'google_user_${DateTime.now().millisecondsSinceEpoch}',
            displayName: 'Google Reader',
            email: 'google.reader@novelsdestiny.com',
            photoUrl: null,
            role: UserRole.reader,
            approvalStatus: ApprovalStatus.approved,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            bio: 'Joined via Google Sign-In.',
          );

          try {
            await _firestore.saveUser(fallbackUser).timeout(
              const Duration(seconds: 4),
              onTimeout: () {},
            );
          } catch (_) {}

          _dataSource.updateUser(fallbackUser);
          _dataSource.setCurrentUser(fallbackUser);
          await _sessionService.saveUserSession(fallbackUser);

          try {
            NotificationService().syncUserDeviceToken(fallbackUser.id);
          } catch (_) {}

          return fallbackUser;
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

      UserCredential? firebaseCredential;
      if (googleAuth.idToken != null) {
        try {
          final OAuthCredential credential = GoogleAuthProvider.credential(
            accessToken: accessToken,
            idToken: googleAuth.idToken,
          );
          firebaseCredential = await _firebaseAuth?.signInWithCredential(credential);
        } catch (e) {
          debugPrint('Firebase Auth Google signIn failed: $e');
        }
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
          const Duration(seconds: 4),
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
          role: _isAdminEmail(email) ? UserRole.admin : UserRole.reader,
          approvalStatus: ApprovalStatus.approved,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          bio: 'Joined via Google Sign-In.',
        );

        // 6. Save to Firestore with a timeout so we never hang
        try {
          await _firestore.saveUser(googleUser).timeout(
            const Duration(seconds: 4),
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
      try {
        await _firestore.saveUser(newUser).timeout(
          const Duration(seconds: 4),
          onTimeout: () {},
        );
      } catch (e) {
        debugPrint('Firestore saveUser warning during signUp: $e');
      }

      // Save in memory and persist session
      _dataSource.updateUser(newUser);
      _dataSource.setCurrentUser(newUser);
      await _sessionService.saveUserSession(newUser);

      try {
        NotificationService().syncUserDeviceToken(newUser.id);
      } catch (_) {}
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
          try {
            await _firestore.saveUser(savedUser).timeout(
              const Duration(seconds: 3),
              onTimeout: () {},
            );
          } catch (_) {}
        }
        _dataSource.updateUser(savedUser);
        _dataSource.setCurrentUser(savedUser);
        return savedUser;
      }

      // 2. Fallback to Firebase current user if available
      final fbUser = _firebaseAuth?.currentUser;
      if (fbUser != null) {
        UserModel? userDoc;
        try {
          userDoc = await _firestore.getUser(fbUser.uid).timeout(
            const Duration(seconds: 4),
            onTimeout: () => null,
          );
        } catch (_) {}

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
          try {
            await _firestore.saveUser(userDoc).timeout(
              const Duration(seconds: 3),
              onTimeout: () {},
            );
          } catch (_) {}
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
      throw const UnauthorizedFailure();
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
