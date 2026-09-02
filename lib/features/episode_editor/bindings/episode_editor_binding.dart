import 'package:get/get.dart';
import '../controllers/episode_editor_controller.dart';
import '../../../domain/usecases/episode_usecases.dart';
import '../../../core/services/logger_service.dart';

class EpisodeEditorBinding extends Bindings {
  @override
  void dependencies() {
    final novelId = Get.parameters['novelId'] ?? '';
    // episodeId is null when adding a new chapter
    final episodeId = Get.parameters['episodeId'];
    final tag = '$novelId-${episodeId ?? '__new__'}';

    Get.put<EpisodeEditorController>(
      EpisodeEditorController(
        novelId,
        episodeId,
        Get.find<EpisodeUseCases>(),
        Get.find<ILoggerService>(),
      ),
      tag: tag,
      permanent: false,
    );
  }
}
