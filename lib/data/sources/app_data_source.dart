import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../models/novel_model.dart';
import '../models/episode_model.dart';
import '../models/reading_progress_model.dart';
import '../models/report_model.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/novel_entity.dart';

import '../../domain/entities/report_entity.dart';
import '../../domain/entities/analytics_entity.dart';

/// In-memory cache layer that sits in front of Firestore.
/// No seed/dummy data — all content comes from real Firebase uploads.
class AppDataSource {
  static final AppDataSource _instance = AppDataSource._internal();
  factory AppDataSource() => _instance;

  AppDataSource._internal();

  // In-memory collections mimicking Cloud Firestore
  final Map<String, UserModel> _users = {};
  final Map<String, NovelModel> _novels = {};
  final Map<String, List<EpisodeModel>> _episodes = {}; // key: novelId
  final Map<String, Set<String>> _novelLikes = {}; // key: novelId -> Set<userId>
  final Map<String, Set<String>> _userLibrary = {}; // key: userId -> Set<novelId>
  final Map<String, Map<String, ReadingProgressModel>> _userReadingProgress = {}; // userId -> {novelId -> progress}
  final Map<String, Set<String>> _userDownloads = {}; // key: userId -> Set<novelId>
  final Map<String, ReportModel> _reports = {};

  // Auth state
  UserModel? _currentUser;
  final StreamController<UserModel?> _authStateController = StreamController<UserModel?>.broadcast();

  Stream<UserModel?> get authStateStream => _authStateController.stream;
  UserModel? get currentUser => _currentUser;

  void setCurrentUser(UserModel? user) {
    _currentUser = user;
    _authStateController.add(_currentUser);
  }

  // --- Cache population (called by repositories after Firestore fetch) ---

  /// Bulk-load novels from Firestore into the local cache.
  void loadNovels(List<NovelModel> novels) {
    for (final novel in novels) {
      _novels[novel.id] = novel;
    }
  }

  /// Bulk-load episodes into the local cache.
  void loadEpisodes(String novelId, List<EpisodeModel> episodes) {
    _episodes[novelId] = List.from(episodes);
  }

  // --- Novel methods ---
  Future<List<NovelModel>> getFeaturedNovels() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _novels.values.where((n) => n.isPubliclyVisible).toList();
  }

  Future<List<NovelModel>> getTrendingNovels() async {
    await Future.delayed(const Duration(milliseconds: 50));
    final list = _novels.values.where((n) => n.isPubliclyVisible).toList();
    list.sort((a, b) => b.totalViews.compareTo(a.totalViews));
    return list;
  }

  Future<List<NovelModel>> getNovelsByGenre(String genre) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _novels.values
        .where((n) => n.isPubliclyVisible && n.genreIds.any((g) => g.toLowerCase() == genre.toLowerCase()))
        .toList();
  }

  Future<List<NovelModel>> searchNovels(String query, {String? genre, String? status}) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final q = query.trim().toLowerCase();
    return _novels.values.where((n) {
      if (!n.isPubliclyVisible && n.writerId != _currentUser?.id && _currentUser?.role != UserRole.admin) {
        return false;
      }
      final matchesQuery = q.isEmpty ||
          n.titleLowercase.contains(q) ||
          n.writerName.toLowerCase().contains(q) ||
          n.tags.any((t) => t.toLowerCase().contains(q)) ||
          n.genreIds.any((g) => g.toLowerCase().contains(q));
      final matchesGenre = genre == null || genre.isEmpty || n.genreIds.contains(genre);
      final matchesStatus = status == null || status.isEmpty || n.status.name == status;
      return matchesQuery && matchesGenre && matchesStatus;
    }).toList();
  }

  Future<NovelModel?> getNovelById(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _novels[id];
  }

  Future<List<NovelModel>> getNovelsByWriter(String writerId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _novels.values.where((n) => n.writerId == writerId).toList();
  }

  Future<NovelModel> saveNovel(NovelModel novel) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _novels[novel.id] = novel;
    return novel;
  }

  Future<void> deleteNovel(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _novels.remove(id);
    _episodes.remove(id);
  }

  // --- Episode methods ---
  Future<List<EpisodeModel>> getEpisodesForNovel(String novelId, {bool publishedOnly = true}) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final list = _episodes[novelId] ?? [];
    if (publishedOnly) {
      return list.where((e) => e.isPublished).toList();
    }
    return List.from(list);
  }

  Future<EpisodeModel?> getEpisodeById(String novelId, String episodeId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final list = _episodes[novelId] ?? [];
    try {
      return list.firstWhere((e) => e.id == episodeId);
    } catch (_) {
      return null;
    }
  }

  Future<EpisodeModel> saveEpisode(EpisodeModel episode) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final list = _episodes[episode.novelId] ?? [];
    final idx = list.indexWhere((e) => e.id == episode.id);
    if (idx >= 0) {
      list[idx] = episode;
    } else {
      list.add(episode);
    }
    _episodes[episode.novelId] = list;

    // Update novel published count
    final novel = _novels[episode.novelId];
    if (novel != null) {
      final publishedCount = list.where((e) => e.isPublished).length;
      _novels[episode.novelId] = NovelModel.fromEntity(novel.copyWith(
        publishedEpisodeCount: publishedCount,
        updatedAt: DateTime.now(),
      ));
    }
    return episode;
  }

  Future<void> deleteEpisode(String novelId, String episodeId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final list = _episodes[novelId] ?? [];
    list.removeWhere((e) => e.id == episodeId);
    _episodes[novelId] = list;
  }

  // --- Interactions ---
  bool isNovelLiked(String novelId, String userId) {
    return _novelLikes[novelId]?.contains(userId) ?? false;
  }

  void toggleLikeNovel(String novelId, String userId) {
    final set = _novelLikes[novelId] ?? <String>{};
    if (set.contains(userId)) {
      set.remove(userId);
      final n = _novels[novelId];
      if (n != null && n.totalLikes > 0) {
        _novels[novelId] = NovelModel.fromEntity(n.copyWith(totalLikes: n.totalLikes - 1));
      }
    } else {
      set.add(userId);
      final n = _novels[novelId];
      if (n != null) {
        _novels[novelId] = NovelModel.fromEntity(n.copyWith(totalLikes: n.totalLikes + 1));
      }
    }
    _novelLikes[novelId] = set;
  }

  bool isNovelSaved(String novelId, String userId) {
    return _userLibrary[userId]?.contains(novelId) ?? false;
  }

  void toggleSaveNovel(String novelId, String userId) {
    final set = _userLibrary[userId] ?? <String>{};
    if (set.contains(novelId)) {
      set.remove(novelId);
    } else {
      set.add(novelId);
    }
    _userLibrary[userId] = set;
  }

  List<NovelModel> getSavedNovels(String userId) {
    final ids = _userLibrary[userId] ?? {};
    return ids.map((id) => _novels[id]).whereType<NovelModel>().toList();
  }

  void saveReadingProgress(String userId, ReadingProgressModel progress) {
    final userMap = _userReadingProgress[userId] ?? {};
    userMap[progress.novelId] = progress;
    _userReadingProgress[userId] = userMap;
  }

  ReadingProgressModel? getReadingProgress(String userId, String novelId) {
    return _userReadingProgress[userId]?[novelId];
  }

  List<ReadingProgressModel> getReadingHistory(String userId) {
    final map = _userReadingProgress[userId] ?? {};
    final list = map.values.toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  void recordDownload(String userId, String novelId) {
    final set = _userDownloads[userId] ?? <String>{};
    set.add(novelId);
    _userDownloads[userId] = set;

    final n = _novels[novelId];
    if (n != null) {
      _novels[novelId] = NovelModel.fromEntity(n.copyWith(totalDownloads: n.totalDownloads + 1));
    }
  }

  List<NovelModel> getDownloadedNovels(String userId) {
    final ids = _userDownloads[userId] ?? {};
    return ids.map((id) => _novels[id]).whereType<NovelModel>().toList();
  }

  // --- Users ---
  List<UserModel> getAllUsers() => _users.values.toList();

  List<UserModel> getPendingWriters() {
    return _users.values
        .where((u) => u.role == UserRole.writer && u.approvalStatus == ApprovalStatus.pending)
        .toList();
  }

  UserModel? getUserById(String id) => _users[id];

  void approveWriter(String userId) {
    final user = _users[userId];
    if (user != null) {
      final updated = user.copyWith(
        approvalStatus: ApprovalStatus.approved,
        updatedAt: DateTime.now(),
      ) as UserModel;
      _users[userId] = updated;
      if (_currentUser?.id == userId) {
        setCurrentUser(updated);
      }
    }
  }

  void rejectWriter(String userId) {
    final user = _users[userId];
    if (user != null) {
      final updated = user.copyWith(
        approvalStatus: ApprovalStatus.rejected,
        updatedAt: DateTime.now(),
      ) as UserModel;
      _users[userId] = updated;
      if (_currentUser?.id == userId) {
        setCurrentUser(updated);
      }
    }
  }

  void updateUser(UserModel user) {
    _users[user.id] = user;
    if (_currentUser?.id == user.id) {
      setCurrentUser(user);
    }
  }

  // --- Moderation & Reports ---
  List<NovelModel> getPendingNovels() {
    return _novels.values.where((n) => n.moderationStatus == ModerationStatus.pending).toList();
  }

  void updateNovelModerationStatus(String novelId, ModerationStatus status) {
    final n = _novels[novelId];
    if (n != null) {
      _novels[novelId] = NovelModel.fromEntity(n.copyWith(moderationStatus: status, updatedAt: DateTime.now()));
    }
  }

  List<ReportModel> getReports({ReportStatus? status}) {
    if (status != null) {
      return _reports.values.where((r) => r.status == status).toList();
    }
    return _reports.values.toList();
  }

  void saveReport(ReportModel report) {
    _reports[report.id] = report;
  }

  // --- Analytics (computed from real cached data) ---
  PlatformAnalyticsEntity getPlatformAnalytics() {
    final totalUsers = _users.length;
    final totalReaders = _users.values.where((u) => u.isReader).length;
    final totalWriters = _users.values.where((u) => u.isWriter).length;
    final totalNovels = _novels.length;
    final totalPublishedEpisodes = _episodes.values.fold<int>(0, (sum, list) => sum + list.where((e) => e.isPublished).length);
    final totalReads = _novels.values.fold<int>(0, (sum, n) => sum + n.totalViews);
    final totalLikes = _novels.values.fold<int>(0, (sum, n) => sum + n.totalLikes);
    final totalDownloads = _novels.values.fold<int>(0, (sum, n) => sum + n.totalDownloads);
    final pendingMods = _novels.values.where((n) => n.moderationStatus == ModerationStatus.pending).length;
    final openReps = _reports.values.where((r) => r.status == ReportStatus.pending).length;

    return PlatformAnalyticsEntity(
      totalUsers: totalUsers,
      totalReaders: totalReaders,
      totalWriters: totalWriters,
      totalNovels: totalNovels,
      totalPublishedEpisodes: totalPublishedEpisodes,
      totalReads: totalReads,
      totalLikes: totalLikes,
      totalDownloads: totalDownloads,
      pendingModerations: pendingMods,
      openReports: openReps,
      dailyReadsTrend: const [],
      dailyUsersTrend: const [],
    );
  }

  /// Clears in-memory cache. For unit tests only (singleton isolation).
  @visibleForTesting
  void resetForTesting() {
    _users.clear();
    _novels.clear();
    _episodes.clear();
    _novelLikes.clear();
    _userLibrary.clear();
    _userReadingProgress.clear();
    _userDownloads.clear();
    _reports.clear();
    _currentUser = null;
    _authStateController.add(null);
  }

  WriterAnalyticsEntity getWriterAnalytics(String writerId) {
    final writerNovels = _novels.values.where((n) => n.writerId == writerId).toList();
    final totalNovels = writerNovels.length;
    final publishedEpisodes = writerNovels.fold<int>(0, (sum, n) => sum + n.publishedEpisodeCount);
    final totalReads = writerNovels.fold<int>(0, (sum, n) => sum + n.totalViews);
    final totalLikes = writerNovels.fold<int>(0, (sum, n) => sum + n.totalLikes);
    final totalDownloads = writerNovels.fold<int>(0, (sum, n) => sum + n.totalDownloads);

    return WriterAnalyticsEntity(
      writerId: writerId,
      totalNovels: totalNovels,
      publishedEpisodes: publishedEpisodes,
      totalReads: totalReads,
      totalLikes: totalLikes,
      totalDownloads: totalDownloads,
      dailyReadsTrend: const [],
    );
  }
}
