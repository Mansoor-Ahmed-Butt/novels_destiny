import 'package:flutter_test/flutter_test.dart';
import 'package:novels_destiny/domain/entities/user_entity.dart';
import 'package:novels_destiny/domain/repositories/auth_repository.dart';
import 'package:novels_destiny/domain/usecases/auth_usecases.dart';
import 'package:novels_destiny/core/services/logger_service.dart';
import 'package:novels_destiny/features/auth/controllers/auth_controller.dart';

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
