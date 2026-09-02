import 'package:get/get.dart';
import '../controllers/novel_editor_controller.dart';
import '../../../domain/usecases/novel_usecases.dart';
import '../../../core/services/logger_service.dart';

class NovelEditorBinding extends Bindings {
  @override
  void dependencies() {
    // novelId is null when creating a new novel (no ?id= param)
    final novelId = Get.parameters['id'];
    final tag = novelId ?? '__new_novel__';

    Get.put<NovelEditorController>(
      NovelEditorController(
        novelId,
        Get.find<NovelUseCases>(),
        Get.find<ILoggerService>(),
      ),
      tag: tag,
      permanent: false,
    );
  }
}
