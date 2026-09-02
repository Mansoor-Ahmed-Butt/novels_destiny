import 'dart:async';
import 'package:get/get.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/usecases/auth_usecases.dart';
import '../states/auth_state.dart';
import '../../../core/errors/failures.dart';
import '../../../core/services/logger_service.dart';

class AuthController extends GetxController {
  final AuthUseCases _authUseCases;
  final ILoggerService _logger;

  AuthController(this._authUseCases, this._logger);

  final Rx<AuthState> state = Rx<AuthState>(const AuthInitial());
  final Rx<UserEntity?> currentUser = Rx<UserEntity?>(null);
  StreamSubscription<UserEntity?>? _authSubscription;

  @override
  void onInit() {
    super.onInit();
    _initAuthListener();
  }

  void _initAuthListener() {
    final current = _authUseCases.currentUser;
    if (current != null) {
      currentUser.value = current;
      state.value = Authenticated(current);
    } else {
      state.value = const Unauthenticated();
    }

    _authSubscription = _authUseCases.authStateChanges().listen((user) {
      currentUser.value = user;
      if (user != null) {
        state.value = Authenticated(user);
      } else {
        state.value = const Unauthenticated();
      }
    });
  }

  Future<void> signIn(String email, String password) async {
    try {
      state.value = const AuthLoading();
      final user = await _authUseCases.signIn(email, password);
      currentUser.value = user;
      state.value = Authenticated(user);
      _logger.info('User signed in: ${user.email} (${user.role.name})');
    } on AppFailure catch (e) {
      state.value = AuthFailureState(e.message);
      _logger.warning('Sign-in failure: ${e.message}');
    } catch (e) {
      state.value = const AuthFailureState('Failed to sign in. Please try again.');
      _logger.error('Unexpected sign in error', e);
    }
  }

  Future<void> signUp(String email, String password, String displayName, UserRole role) async {
    try {
      state.value = const AuthLoading();
      final user = await _authUseCases.signUp(email, password, displayName, role);
      currentUser.value = user;
      state.value = Authenticated(user);
      _logger.info('User signed up: ${user.email} as ${user.role.name}');
    } on AppFailure catch (e) {
      state.value = AuthFailureState(e.message);
    } catch (e) {
      state.value = const AuthFailureState('Failed to create account.');
      _logger.error('Unexpected sign up error', e);
    }
  }

  Future<void> signOut() async {
    await _authUseCases.signOut();
    currentUser.value = null;
    state.value = const Unauthenticated();
  }

  Future<void> switchRole(UserRole newRole) async {
    try {
      final updated = await _authUseCases.switchRole(newRole);
      currentUser.value = updated;
      state.value = Authenticated(updated);
      _logger.info('Role switched to: ${newRole.name}');
    } catch (e) {
      _logger.error('Failed to switch role', e);
    }
  }

  Future<void> updateProfile({String? displayName, String? bio, String? photoUrl}) async {
    try {
      final updated = await _authUseCases.updateProfile(displayName: displayName, bio: bio, photoUrl: photoUrl);
      currentUser.value = updated;
      state.value = Authenticated(updated);
    } catch (e) {
      _logger.error('Failed to update profile', e);
    }
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    super.onClose();
  }
}
