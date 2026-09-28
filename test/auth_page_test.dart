import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:novels_destiny/domain/entities/user_entity.dart';
import 'package:novels_destiny/domain/repositories/auth_repository.dart';
import 'package:novels_destiny/domain/usecases/auth_usecases.dart';
import 'package:novels_destiny/core/services/logger_service.dart';
import 'package:novels_destiny/features/auth/controllers/auth_controller.dart';
import 'package:novels_destiny/features/auth/pages/auth_page.dart';

class FakeAuthRepository implements IAuthRepository {
  @override
  Stream<UserEntity?> authStateChanges() => Stream.value(null);
  @override
  UserEntity? get currentUser => null;
  @override
  Future<UserEntity> signInWithEmailPassword(String email, String password) async => throw UnimplementedError();
  @override
  Future<UserEntity> signInWithGoogle() async => throw UnimplementedError();
  @override
  Future<UserEntity> signUpWithEmailPassword(String email, String password, String displayName, UserRole role) async => throw UnimplementedError();
  @override
  Future<UserEntity?> restoreSession() async => null;
  @override
  Future<void> signOut() async {}
  @override
  Future<UserEntity> switchRole(UserRole newRole) async => throw UnimplementedError();
  @override
  Future<UserEntity> updateProfile({String? displayName, String? bio, String? photoUrl}) async => throw UnimplementedError();
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

  late AuthController authController;

  setUp(() {
    Get.reset();
    final repo = FakeAuthRepository();
    final useCases = AuthUseCases(repo);
    final logger = FakeLoggerService();
    authController = AuthController(useCases, logger);
    Get.put<AuthController>(authController);
  });

  tearDown(() {
    Get.reset();
  });

  group('AuthPage GetX Reactive Widget Tests', () {
    testWidgets('Toggles sign-in and sign-up forms reactively', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(
          home: AuthPage(),
        ),
      );

      // Initially in sign-in mode
      expect(find.text('Sign In'), findsWidgets);
      expect(find.text("Don't have an account? Create one"), findsOneWidget);
      expect(find.text('Full Name'), findsNothing);

      // Tap toggle to switch to sign-up
      final toggleFinder = find.text("Don't have an account? Create one");
      await tester.ensureVisible(toggleFinder);
      await tester.tap(toggleFinder);
      await tester.pumpAndSettle();

      expect(authController.isSignUp.value, true);
      expect(find.text('Full Name'), findsOneWidget);
      final signInToggle = find.text('Already have an account? Sign In');
      expect(signInToggle, findsOneWidget);

      // Tap toggle to switch back to sign-in
      await tester.ensureVisible(signInToggle);
      await tester.tap(signInToggle);
      await tester.pumpAndSettle();

      expect(authController.isSignUp.value, false);
      expect(find.text('Full Name'), findsNothing);
    });

    testWidgets('Toggles admin portal mode and updates UI header without prefilled credentials', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(
          home: AuthPage(),
        ),
      );

      // Initially reader sign-in with empty credentials
      expect(find.text('Novels Destiny'), findsOneWidget);
      expect(authController.emailController.text, '');
      expect(authController.passwordController.text, '');

      // Toggle Admin Mode switch
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(authController.isAdminMode.value, true);
      expect(authController.emailController.text, '');
      expect(authController.passwordController.text, '');
      expect(find.text('Admin Portal'), findsOneWidget);
    });
  });
}
