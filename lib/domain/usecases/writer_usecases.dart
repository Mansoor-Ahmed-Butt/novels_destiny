import '../entities/analytics_entity.dart';
import '../repositories/analytics_repository.dart';

class WriterUseCases {
  final IAnalyticsRepository _analyticsRepository;

  WriterUseCases(this._analyticsRepository);

  Future<WriterAnalyticsEntity> getWriterAnalytics(String writerId) =>
      _analyticsRepository.getWriterAnalytics(writerId);
}
