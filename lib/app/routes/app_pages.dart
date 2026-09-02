import 'package:get/get.dart';
import 'app_routes.dart';
import '../../features/auth/pages/auth_page.dart';
import '../../features/auth/bindings/auth_binding.dart';
import '../../features/main_shell/main_shell_page.dart';
import '../../features/novels/pages/novel_details_page.dart';
import '../../features/novels/bindings/novel_details_binding.dart';
import '../../features/reader/pages/episode_reader_page.dart';
import '../../features/reader/bindings/episode_reader_binding.dart';
import '../../features/novel_editor/pages/novel_editor_page.dart';
import '../../features/novel_editor/bindings/novel_editor_binding.dart';
import '../../features/episode_editor/pages/episode_editor_page.dart';
import '../../features/episode_editor/bindings/episode_editor_binding.dart';
import '../../features/home/bindings/home_binding.dart';
import '../../features/library/bindings/library_binding.dart';
import '../../features/writer_dashboard/bindings/writer_dashboard_binding.dart';
import '../../features/admin_dashboard/bindings/admin_dashboard_binding.dart';
import '../../features/profile/bindings/profile_binding.dart';

class AppPages {
  AppPages._();

  static const initial = AppRoutes.shell;

  static final routes = [
    GetPage(
      name: AppRoutes.auth,
      page: () => const AuthPage(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.shell,
      page: () => const MainShellPage(),
      bindings: [
        HomeBinding(),
        LibraryBinding(),
        WriterDashboardBinding(),
        AdminDashboardBinding(),
        ProfileBinding(),
      ],
    ),
    GetPage(
      name: AppRoutes.novelDetailsBase,
      page: () => const NovelDetailsPage(),
      binding: NovelDetailsBinding(),
    ),
    GetPage(
      name: AppRoutes.episodeReaderBase,
      page: () => const EpisodeReaderPage(),
      binding: EpisodeReaderBinding(),
    ),
    GetPage(
      name: AppRoutes.novelEditorBase,
      page: () => const NovelEditorPage(),
      binding: NovelEditorBinding(),
    ),
    GetPage(
      name: AppRoutes.episodeEditorBase,
      page: () => const EpisodeEditorPage(),
      binding: EpisodeEditorBinding(),
    ),
  ];
}
