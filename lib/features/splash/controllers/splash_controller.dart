import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../domain/entities/user_entity.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../main_shell/main_shell_page.dart';

class SplashController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();

  @override
  void onReady() {
    super.onReady();
    _checkInitialSession();
  }

  Future<void> _checkInitialSession() async {
    // Smooth, professional delay to display branding
    await Future.delayed(const Duration(milliseconds: 400));

    // Check existing or persisted user session
    UserEntity? user = _authController.currentUser.value;
    if (user == null) {
      user = await _authController.restoreSession();
    }

    if (user != null) {
      // User is already logged in, navigate straight into the app!
      if (user.role == UserRole.writer &&
          user.approvalStatus == ApprovalStatus.pending) {
        Get.offAllNamed(AppRoutes.writerPendingApproval);
      } else {
        if (Get.isRegistered<MainShellController>()) {
          Get.find<MainShellController>().setInitialTabForRole(user.role);
        }
        Get.offAllNamed(AppRoutes.shell);
      }
    } else {
      // Unauthenticated, show the Sign In page
      Get.offAllNamed(AppRoutes.auth);
    }
  }
}
