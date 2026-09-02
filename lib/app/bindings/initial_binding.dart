import 'package:get/get.dart';
import '../../core/services/logger_service.dart';
import '../../data/sources/app_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/novel_repository_impl.dart';
import '../../data/repositories/episode_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../data/repositories/analytics_repository_impl.dart';
import '../../data/repositories/moderation_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/novel_repository.dart';
import '../../domain/repositories/episode_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../../domain/repositories/moderation_repository.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../../domain/usecases/novel_usecases.dart';
import '../../domain/usecases/episode_usecases.dart';
import '../../domain/usecases/writer_usecases.dart';
import '../../domain/usecases/admin_usecases.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/home/controllers/home_controller.dart';
import '../../features/library/controllers/library_controller.dart';
import '../../features/writer_dashboard/controllers/writer_dashboard_controller.dart';
import '../../features/admin_dashboard/controllers/admin_dashboard_controller.dart';
import '../../features/profile/controllers/profile_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // 1. Core Services
    Get.put<ILoggerService>(const LoggerService(), permanent: true);

    // 2. Data Sources
    final dataSource = AppDataSource();
    Get.put<AppDataSource>(dataSource, permanent: true);

    // 3. Repositories
    Get.put<IAuthRepository>(AuthRepositoryImpl(dataSource), permanent: true);
    Get.put<INovelRepository>(NovelRepositoryImpl(dataSource), permanent: true);
    Get.put<IEpisodeRepository>(EpisodeRepositoryImpl(dataSource), permanent: true);
    Get.put<IUserRepository>(UserRepositoryImpl(dataSource), permanent: true);
    Get.put<IAnalyticsRepository>(AnalyticsRepositoryImpl(dataSource), permanent: true);
    Get.put<IModerationRepository>(ModerationRepositoryImpl(dataSource), permanent: true);

    // 4. Use Cases
    Get.put<AuthUseCases>(AuthUseCases(Get.find()), permanent: true);
    Get.put<NovelUseCases>(NovelUseCases(Get.find()), permanent: true);
    Get.put<EpisodeUseCases>(EpisodeUseCases(Get.find()), permanent: true);
    Get.put<WriterUseCases>(WriterUseCases(Get.find()), permanent: true);
    Get.put<AdminUseCases>(AdminUseCases(Get.find(), Get.find(), Get.find()), permanent: true);

    // 5. Long-lived Auth Controller
    Get.put<AuthController>(AuthController(Get.find(), Get.find()), permanent: true);

    // 6. Navigation Shell Controllers
    Get.put<HomeController>(HomeController(Get.find(), Get.find()), permanent: true);
    Get.put<LibraryController>(LibraryController(Get.find(), Get.find()), permanent: true);
    Get.put<WriterDashboardController>(WriterDashboardController(Get.find(), Get.find(), Get.find()), permanent: true);
    Get.put<AdminDashboardController>(AdminDashboardController(Get.find(), Get.find()), permanent: true);
    Get.put<ProfileController>(ProfileController(Get.find()), permanent: true);
  }
}
