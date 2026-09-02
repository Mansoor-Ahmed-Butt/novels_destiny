import 'package:get/get.dart';
import '../controllers/episode_reader_controller.dart';
import '../../../domain/usecases/novel_usecases.dart';
import '../../../domain/usecases/episode_usecases.dart';
import '../../../core/services/logger_service.dart';

class EpisodeReaderBinding extends Bindings {
  @override
  void dependencies() {
    final novelId = Get.parameters['novelId'] ?? '';
    final episodeId = Get.parameters['episodeId'] ?? '';
    final tag = '$novelId-$episodeId';

    Get.put<EpisodeReaderController>(
      EpisodeReaderController(
        novelId,
        episodeId,
        Get.find<NovelUseCases>(),
        Get.find<EpisodeUseCases>(),
        Get.find<ILoggerService>(),
      ),
      tag: tag,
      permanent: false,
    );
  }
}
