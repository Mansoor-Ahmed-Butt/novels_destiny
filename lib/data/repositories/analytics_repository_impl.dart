import '../../domain/entities/analytics_entity.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../sources/app_data_source.dart';
import '../sources/firestore_data_source.dart';
import '../../core/errors/failures.dart';

class AnalyticsRepositoryImpl implements IAnalyticsRepository {
  final AppDataSource _dataSource;
  final FirestoreDataSource _firestore = FirestoreDataSource();

  AnalyticsRepositoryImpl(this._dataSource);

  @override
  Future<PlatformAnalyticsEntity> getPlatformAnalytics() async {
    try {
      // Sync users and novels from Firestore so real analytics are computed
      final remoteUsers = await _firestore.getAllUsers();
      for (final user in remoteUsers) {
        _dataSource.updateUser(user);
      }
      final remoteNovels = await _firestore.getAllNovels();
      _dataSource.loadNovels(remoteNovels);

      return _dataSource.getPlatformAnalytics();
    } catch (e) {
      return _dataSource.getPlatformAnalytics();
    }
  }

  @override
  Future<WriterAnalyticsEntity> getWriterAnalytics(String writerId) async {
    try {
      return _dataSource.getWriterAnalytics(writerId);
    } catch (e) {
      throw UnknownFailure('Failed to fetch author analytics: $e');
    }
  }
}
