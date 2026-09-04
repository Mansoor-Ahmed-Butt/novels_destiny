import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/novel_model.dart';
import '../models/episode_model.dart';
import '../models/content_block_model.dart';
import '../models/reading_progress_model.dart';
import '../models/report_model.dart';
import '../../domain/entities/content_block_entity.dart';

class FirestoreDataSource {
  static final FirestoreDataSource _instance = FirestoreDataSource._internal();
  factory FirestoreDataSource() => _instance;
  FirestoreDataSource._internal();

  FirebaseFirestore? get _firestore {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
    } catch (_) {}
    return null;
  }

  // Collection References (null-safe for unit tests / offline runs)
  CollectionReference<Map<String, dynamic>>? get _usersCol => _firestore?.collection('users');
  CollectionReference<Map<String, dynamic>>? get _novelsCol => _firestore?.collection('novels');
  CollectionReference<Map<String, dynamic>>? get _episodesCol => _firestore?.collection('episodes');
  CollectionReference<Map<String, dynamic>>? get _progressCol => _firestore?.collection('reading_progress');
  CollectionReference<Map<String, dynamic>>? get _bookmarksCol => _firestore?.collection('bookmarks');
  CollectionReference<Map<String, dynamic>>? get _followersCol => _firestore?.collection('novel_followers');
  CollectionReference<Map<String, dynamic>>? get _reportsCol => _firestore?.collection('reports');
  CollectionReference<Map<String, dynamic>>? get _notificationsCol => _firestore?.collection('notifications');

  // ================= USERS =================
  Future<void> saveUser(UserModel user) async {
    final col = _usersCol;
    if (col == null) return;
    try {
      await col.doc(user.id).set(user.toJson(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore saveUser warning: $e');
    }
  }

  Future<UserModel?> getUser(String uid) async {
    final col = _usersCol;
    if (col == null) return null;
    try {
      final doc = await col.doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!);
      }
    } catch (e) {
      debugPrint('Firestore getUser warning: $e');
    }
    return null;
  }

  Future<List<UserModel>> getAllUsers() async {
    final col = _usersCol;
    if (col == null) return [];
    try {
      final snapshot = await col.get();
      return snapshot.docs.map((d) => UserModel.fromJson(d.data())).toList();
    } catch (e) {
      debugPrint('Firestore getAllUsers warning: $e');
      return [];
    }
  }

  // ================= NOVELS =================
  Future<void> saveNovel(NovelModel novel) async {
    final col = _novelsCol;
    if (col == null) return;
    try {
      await col.doc(novel.id).set(novel.toJson(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore saveNovel warning: $e');
    }
  }

  Future<NovelModel?> getNovel(String id) async {
    final col = _novelsCol;
    if (col == null) return null;
    try {
      final doc = await col.doc(id).get();
      if (doc.exists && doc.data() != null) {
        return NovelModel.fromJson(doc.data()!);
      }
    } catch (e) {
      debugPrint('Firestore getNovel warning: $e');
    }
    return null;
  }

  Future<List<NovelModel>> getAllNovels() async {
    final col = _novelsCol;
    if (col == null) return [];
    try {
      final snapshot = await col.get();
      return snapshot.docs.map((d) => NovelModel.fromJson(d.data())).toList();
    } catch (e) {
      debugPrint('Firestore getAllNovels warning: $e');
      return [];
    }
  }

  Future<void> incrementNovelViews(String novelId) async {
    final col = _novelsCol;
    if (col == null) return;
    try {
      await col.doc(novelId).update({'totalViews': FieldValue.increment(1)});
    } catch (e) {
      debugPrint('Firestore incrementNovelViews warning: $e');
    }
  }

  Future<void> incrementNovelLikes(String novelId) async {
    final col = _novelsCol;
    if (col == null) return;
    try {
      await col.doc(novelId).update({'totalLikes': FieldValue.increment(1)});
    } catch (e) {
      debugPrint('Firestore incrementNovelLikes warning: $e');
    }
  }

  // ================= EPISODES & BLOCKS =================
  Future<void> saveEpisode(EpisodeModel episode) async {
    final col = _episodesCol;
    final fs = _firestore;
    if (col == null || fs == null) return;
    try {
      await col.doc(episode.id).set(episode.toJson(), SetOptions(merge: true));

      // Save blocks into subcollection: episodes/{episodeId}/blocks/{blockId}
      final blocks = episode.effectiveBlocks;
      final batch = fs.batch();
      final blocksRef = col.doc(episode.id).collection('blocks');

      for (final block in blocks) {
        final blockModel = ContentBlockModel.fromEntity(block);
        batch.set(blocksRef.doc(block.id), blockModel.toJson(), SetOptions(merge: true));
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Firestore saveEpisode warning: $e');
    }
  }

  Future<EpisodeModel?> getEpisode(String episodeId) async {
    final col = _episodesCol;
    if (col == null) return null;
    try {
      final doc = await col.doc(episodeId).get();
      if (doc.exists && doc.data() != null) {
        final blocks = await getEpisodeBlocks(episodeId);
        return EpisodeModel.fromJson(doc.data()!, blocks: blocks);
      }
    } catch (e) {
      debugPrint('Firestore getEpisode warning: $e');
    }
    return null;
  }

  Future<List<EpisodeModel>> getEpisodesForNovel(String novelId) async {
    final col = _episodesCol;
    if (col == null) return [];
    try {
      final snapshot = await col.where('novelId', isEqualTo: novelId).get();

      final list = <EpisodeModel>[];
      for (final doc in snapshot.docs) {
        final ep = EpisodeModel.fromJson(doc.data());
        list.add(ep);
      }
      list.sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));
      return list;
    } catch (e) {
      debugPrint('Firestore getEpisodesForNovel warning: $e');
      return [];
    }
  }

  Future<List<ContentBlockEntity>> getEpisodeBlocks(String episodeId) async {
    final col = _episodesCol;
    if (col == null) return [];
    try {
      final snapshot = await col
          .doc(episodeId)
          .collection('blocks')
          .orderBy('order')
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map((d) => ContentBlockModel.fromJson(d.data()))
            .toList();
      }
    } catch (e) {
      debugPrint('Firestore getEpisodeBlocks warning: $e');
    }
    return [];
  }

  Future<void> incrementEpisodeViews(String episodeId) async {
    final col = _episodesCol;
    if (col == null) return;
    try {
      await col.doc(episodeId).update({'totalViews': FieldValue.increment(1)});
    } catch (e) {
      debugPrint('Firestore incrementEpisodeViews warning: $e');
    }
  }

  // ================= READING PROGRESS =================
  Future<void> saveReadingProgress({
    required String userId,
    required ReadingProgressModel progress,
  }) async {
    final col = _progressCol;
    if (col == null) return;
    try {
      final docId = '${userId}_${progress.novelId}';
      await col.doc(docId).set({
        ...progress.toJson(),
        'userId': userId,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore saveReadingProgress warning: $e');
    }
  }

  Future<ReadingProgressModel?> getReadingProgress({
    required String userId,
    required String novelId,
  }) async {
    final col = _progressCol;
    if (col == null) return null;
    try {
      final docId = '${userId}_$novelId';
      final doc = await col.doc(docId).get();
      if (doc.exists && doc.data() != null) {
        return ReadingProgressModel.fromJson(doc.data()!);
      }
    } catch (e) {
      debugPrint('Firestore getReadingProgress warning: $e');
    }
    return null;
  }

  // ================= BOOKMARKS & LIBRARY =================
  Future<void> toggleBookmark({
    required String userId,
    required String novelId,
    required bool isBookmarked,
  }) async {
    final col = _bookmarksCol;
    if (col == null) return;
    try {
      final docId = '${userId}_$novelId';
      if (isBookmarked) {
        await col.doc(docId).set({
          'userId': userId,
          'novelId': novelId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await col.doc(docId).delete();
      }
    } catch (e) {
      debugPrint('Firestore toggleBookmark warning: $e');
    }
  }

  Future<bool> isNovelBookmarked({required String userId, required String novelId}) async {
    final col = _bookmarksCol;
    if (col == null) return false;
    try {
      final docId = '${userId}_$novelId';
      final doc = await col.doc(docId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> getBookmarkedNovelIds(String userId) async {
    final col = _bookmarksCol;
    if (col == null) return [];
    try {
      final snapshot = await col.where('userId', isEqualTo: userId).get();
      return snapshot.docs.map((d) => d.data()['novelId'] as String? ?? '').where((id) => id.isNotEmpty).toList();
    } catch (e) {
      return [];
    }
  }

  // ================= NOVEL FOLLOWERS =================
  Future<void> toggleFollowNovel({
    required String userId,
    required String novelId,
    required bool isFollowing,
  }) async {
    final col = _followersCol;
    if (col == null) return;
    try {
      final docId = '${userId}_$novelId';
      if (isFollowing) {
        await col.doc(docId).set({
          'userId': userId,
          'novelId': novelId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await col.doc(docId).delete();
      }
    } catch (e) {
      debugPrint('Firestore toggleFollowNovel warning: $e');
    }
  }

  Future<bool> isFollowingNovel({required String userId, required String novelId}) async {
    final col = _followersCol;
    if (col == null) return false;
    try {
      final docId = '${userId}_$novelId';
      final doc = await col.doc(docId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> getNovelFollowerUserIds(String novelId) async {
    final col = _followersCol;
    if (col == null) return [];
    try {
      final snapshot = await col.where('novelId', isEqualTo: novelId).get();
      return snapshot.docs
          .map((d) => d.data()['userId'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ================= NOTIFICATIONS =================
  Future<void> createNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    String? novelId,
    String? episodeId,
  }) async {
    final col = _notificationsCol;
    if (col == null) return;
    try {
      await col.add({
        'userId': userId,
        'type': type,
        'title': title,
        'body': body,
        'novelId': novelId,
        'episodeId': episodeId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Firestore createNotification warning: $e');
    }
  }

  // ================= REPORTS =================
  Future<void> saveReport(ReportModel report) async {
    final col = _reportsCol;
    if (col == null) return;
    try {
      await col.doc(report.id).set(report.toJson(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore saveReport warning: $e');
    }
  }

  Future<List<ReportModel>> getAllReports() async {
    final col = _reportsCol;
    if (col == null) return [];
    try {
      final snapshot = await col.get();
      return snapshot.docs.map((d) => ReportModel.fromJson(d.data())).toList();
    } catch (e) {
      return [];
    }
  }
}
