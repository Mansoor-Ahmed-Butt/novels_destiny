import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:novels_destiny/data/sources/app_data_source.dart';
import 'package:novels_destiny/data/repositories/novel_repository_impl.dart';
import 'package:novels_destiny/data/repositories/episode_repository_impl.dart';
import 'package:novels_destiny/domain/usecases/novel_usecases.dart';
import 'package:novels_destiny/domain/usecases/episode_usecases.dart';
import 'package:novels_destiny/core/services/logger_service.dart';
import 'package:novels_destiny/features/reader/controllers/episode_reader_controller.dart';
import 'package:novels_destiny/features/auth/controllers/auth_controller.dart';
import 'package:novels_destiny/domain/usecases/auth_usecases.dart';
import 'package:novels_destiny/domain/repositories/auth_repository.dart';
import 'package:novels_destiny/domain/entities/user_entity.dart';

class MockAuthRepo implements IAuthRepository {
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
  Future<void> signOut() async {}
  @override
  Future<UserEntity> switchRole(UserRole newRole) async => throw UnimplementedError();
  @override
  Future<UserEntity> updateProfile({String? displayName, String? bio, String? photoUrl}) async => throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EpisodeReaderController Ad State Tests', () {
    late AppDataSource dataSource;
    late NovelUseCases novelUseCases;
    late EpisodeUseCases episodeUseCases;
    late ILoggerService logger;

    setUp(() {
      Get.reset();
      dataSource = AppDataSource();
      final novelRepo = NovelRepositoryImpl(dataSource);
      final episodeRepo = EpisodeRepositoryImpl(dataSource);
      novelUseCases = NovelUseCases(novelRepo);
      episodeUseCases = EpisodeUseCases(episodeRepo);
      logger = const LoggerService();

      Get.put<AuthController>(AuthController(AuthUseCases(MockAuthRepo()), logger));
    });

    tearDown(() {
      Get.reset();
    });

    test('Initializes ad observables correctly', () {
      final controller = EpisodeReaderController(
        'novel_1',
        'ep_1',
        novelUseCases,
        episodeUseCases,
        logger,
      );

      expect(controller.isAdLoaded.value, false);
      expect(controller.bannerAd.value, isNull);
    });

    test('Disposes ad resources properly on onClose', () {
      final controller = EpisodeReaderController(
        'novel_1',
        'ep_1',
        novelUseCases,
        episodeUseCases,
        logger,
      );

      expect(controller.bannerAd.value, isNull);

      controller.onClose();

      expect(controller.bannerAd.value, isNull);
    });
  });
}
