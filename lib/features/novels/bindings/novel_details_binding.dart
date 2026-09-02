import 'package:get/get.dart';
import '../controllers/novel_details_controller.dart';
import '../../../domain/usecases/novel_usecases.dart';
import '../../../domain/usecases/episode_usecases.dart';
import '../../../domain/usecases/admin_usecases.dart';
import '../../../core/services/logger_service.dart';

class NovelDetailsBinding extends Bindings {
  @override
  void dependencies() {
    final novelId = Get.parameters['id'] ?? '';

    Get.put<NovelDetailsController>(
      NovelDetailsController(
        novelId,
        Get.find<NovelUseCases>(),
        Get.find<EpisodeUseCases>(),
        Get.find<AdminUseCases>(),
        Get.find<ILoggerService>(),
      ),
      tag: novelId,
      permanent: false,
    );
  }
}
