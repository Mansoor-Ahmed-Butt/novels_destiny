import '../entities/analytics_entity.dart';

abstract class IAnalyticsRepository {
  Future<PlatformAnalyticsEntity> getPlatformAnalytics();
  Future<WriterAnalyticsEntity> getWriterAnalytics(String writerId);
}
