import 'package:get/get.dart';
import '../controllers/writer_dashboard_controller.dart';

class WriterDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WriterDashboardController>(
      () => WriterDashboardController(Get.find(), Get.find(), Get.find()),
    );
  }
}
