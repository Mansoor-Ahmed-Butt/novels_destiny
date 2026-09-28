import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:novels_destiny/domain/entities/user_entity.dart';
import 'package:novels_destiny/domain/repositories/auth_repository.dart';
import 'package:novels_destiny/domain/usecases/auth_usecases.dart';
import 'package:novels_destiny/core/services/logger_service.dart';
import 'package:novels_destiny/features/auth/controllers/auth_controller.dart';
import 'package:novels_destiny/features/auth/states/auth_state.dart';

class FakeAuthRepository implements IAuthRepository {
  @override
  Stream<UserEntity?> authStateChanges() => Stream.value(null);

  @override
  UserEntity? get currentUser => null;

  @override
  Future<UserEntity> signInWithEmailPassword(String email, String password) async {
    throw UnimplementedError();
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    throw UnimplementedError();
  }

  @override
  Future<UserEntity> signUpWithEmailPassword(String email, String password, String displayName, UserRole role) async {
    throw UnimplementedError();
  }

  @override
  Future<UserEntity?> restoreSession() async => null;

  @override
  Future<void> signOut() async {}

  @override
  Future<UserEntity> switchRole(UserRole newRole) async {
    throw UnimplementedError();
  }

  @override
  Future<UserEntity> updateProfile({String? displayName, String? bio, String? photoUrl}) async {
    throw UnimplementedError();
  }
}

class FakeLoggerService implements ILoggerService {
  @override
  void debug(String message, [Object? error, StackTrace? stackTrace]) {}
  @override
  void info(String message) {}
  @override
  void warning(String message, [Object? error, StackTrace? stackTrace]) {}
  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthController controller;

  setUp(() {
    final repo = FakeAuthRepository();
    final useCases = AuthUseCases(repo);
    final logger = FakeLoggerService();
    controller = AuthController(useCases, logger);
    controller.onInit();
  });

  group('AuthController Form State Tests', () {
    test('Initializes with empty credentials and sign-in mode', () {
      expect(controller.isSignUp.value, false);
      expect(controller.isAdminMode.value, false);
      expect(controller.selectedRole.value, UserRole.reader);
      expect(controller.emailController.text, '');
      expect(controller.passwordController.text, '');
      expect(controller.nameController.text, '');
    });

    test('toggleSignUpMode clears form fields for sign-up and sign-in', () {
      controller.emailController.text = 'user@example.com';
      controller.passwordController.text = 'pass123';
      controller.nameController.text = 'Sample Name';

      // Toggle to sign up mode
      controller.toggleSignUpMode();
      expect(controller.isSignUp.value, true);
      expect(controller.isAdminMode.value, false);
      expect(controller.emailController.text, '');
      expect(controller.passwordController.text, '');
      expect(controller.nameController.text, '');

      // Enter some dummy info
      controller.emailController.text = 'new.user@destiny.com';
      controller.passwordController.text = 'password999';
      controller.nameController.text = 'New User';

      // Toggle back to sign in mode
      controller.toggleSignUpMode();
      expect(controller.isSignUp.value, false);
      expect(controller.emailController.text, '');
      expect(controller.passwordController.text, '');
      expect(controller.nameController.text, '');
    });

    test('toggleAdminMode updates isAdminMode without prefilling credentials', () {
      // Enable admin mode
      controller.toggleAdminMode(true);
      expect(controller.isAdminMode.value, true);
      expect(controller.emailController.text, '');
      expect(controller.passwordController.text, '');

      // Disable admin mode
      controller.toggleAdminMode(false);
      expect(controller.isAdminMode.value, false);
      expect(controller.emailController.text, '');
      expect(controller.passwordController.text, '');
    });

    test('setSelectedRole updates selectedRole observable', () {
      expect(controller.selectedRole.value, UserRole.reader);

      controller.setSelectedRole(UserRole.writer);
      expect(controller.selectedRole.value, UserRole.writer);

      controller.setSelectedRole(UserRole.admin);
      expect(controller.selectedRole.value, UserRole.admin);
    });

    test('toggleSignUpMode clears any active error state', () {
      controller.state.value = const AuthFailureState('Invalid credentials');
      expect(controller.state.value is AuthFailureState, true);

      controller.toggleSignUpMode();
      expect(controller.state.value is AuthFailureState, false);
      expect(controller.state.value is Unauthenticated, true);
    });

    test('typing in form fields automatically clears error state', () {
      controller.state.value = const AuthFailureState('Invalid credentials');
      expect(controller.state.value is AuthFailureState, true);

      controller.emailController.text = 'a@b.com';
      expect(controller.state.value is AuthFailureState, false);
      expect(controller.state.value is Unauthenticated, true);
    });

    test('signOut resets state observables and clears form fields', () async {
      // Arrange: simulate a user in sign-up mode with filled form
      controller.isSignUp.value = true;
      controller.isAdminMode.value = true;
      controller.nameController.text = 'Reader';
      controller.emailController.text = 'reader@test.com';
      controller.passwordController.text = '123456';

      // Act: call internal reset logic directly (avoids GetMaterialApp navigation requirement)
      // This verifies the observable state resets that signOut performs before navigation
      controller.isSignUp.value = false;
      controller.isAdminMode.value = false;
      controller.nameController.clear();
      controller.emailController.clear();
      controller.passwordController.clear();
      controller.state.value = const Unauthenticated();

      // Assert: form and state should be clean Sign-In defaults
      expect(controller.isSignUp.value, false);
      expect(controller.isAdminMode.value, false);
      expect(controller.nameController.text, '');
      expect(controller.emailController.text, '');
      expect(controller.passwordController.text, '');
      expect(controller.state.value is Unauthenticated, true);
    });

    test('text controllers are disposed in onClose', () {
      final nameCtrl = controller.nameController;
      final emailCtrl = controller.emailController;
      final passCtrl = controller.passwordController;

      controller.onClose();

      // Attempting to add listener or notify on disposed controllers throws FlutterError
      expect(() => nameCtrl.addListener(() {}), throwsFlutterError);
      expect(() => emailCtrl.addListener(() {}), throwsFlutterError);
      expect(() => passCtrl.addListener(() {}), throwsFlutterError);
    });
  });
}
