class AppRoutes {
  AppRoutes._();

  static const String initial = '/';
  static const String auth = '/auth';
  static const String writerPendingApproval = '/writer-pending';
  static const String shell = '/shell';
  static const String home = '/home';
  static const String library = '/library';
  static const String writer = '/writer';
  static const String admin = '/admin';
  static const String profile = '/profile';

  static const String novelDetailsBase = '/novels';
  static String novelDetails(String id) => '$novelDetailsBase?id=$id';

  static const String episodeReaderBase = '/reader';
  static String episodeReader(String novelId, String episodeId) =>
      '$episodeReaderBase?novelId=$novelId&episodeId=$episodeId';

  static const String novelEditorBase = '/editor/novel';
  static String novelEditor({String? novelId}) =>
      novelId != null ? '$novelEditorBase?id=$novelId' : novelEditorBase;

  static const String episodeEditorBase = '/editor/episode';
  static String episodeEditor({required String novelId, String? episodeId}) =>
      episodeId != null
      ? '$episodeEditorBase?novelId=$novelId&episodeId=$episodeId'
      : '$episodeEditorBase?novelId=$novelId';
}
