import '../../domain/entities/analytics_entity.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../sources/app_data_source.dart';
import '../../core/errors/failures.dart';

class AnalyticsRepositoryImpl implements IAnalyticsRepository {
  final AppDataSource _dataSource;

  AnalyticsRepositoryImpl(this._dataSource);

  @override
  Future<PlatformAnalyticsEntity> getPlatformAnalytics() async {
    try {
      return _dataSource.getPlatformAnalytics();
    } catch (e) {
      throw UnknownFailure('Failed to fetch platform metrics: $e');
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
