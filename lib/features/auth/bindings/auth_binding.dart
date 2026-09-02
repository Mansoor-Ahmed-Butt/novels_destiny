import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // AuthController is injected as a long-lived dependency via InitialBinding
    if (!Get.isRegistered<AuthController>()) {
      Get.lazyPut<AuthController>(
        () => AuthController(Get.find(), Get.find()),
      );
    }
  }
}
