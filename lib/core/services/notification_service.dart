import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../../domain/usecases/episode_usecases.dart';

/// Top-level background entry-point required by Firebase Cloud Messaging.
/// Wakes up the Dart isolate when a background notification arrives with data.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    debugPrint('FCM Background handler: message ${message.messageId}, data: ${message.data}');
  } catch (e) {
    debugPrint('FCM Background handler error: $e');
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  static NotificationService get to => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'novels_destiny_notifications';
  static const String channelName = 'Novel & Episode Releases';
  static const String channelDescription =
      'Instant notifications when new episodes and novels are published';

  static const String topicAllUsers = 'all_users';
  static const String topicNewReleases = 'new_releases';
  static const String topicNewEpisodes = 'new_episodes';
  static const String topicNewNovels = 'new_novels';

  RemoteMessage? _pendingInitialMessage;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _broadcastSub;
  final DateTime _serviceStartTime = DateTime.now();
  bool _isInitialized = false;

  /// Returns true if an initial launch message was captured from a terminated app start.
  bool get hasPendingLaunchMessage => _pendingInitialMessage != null;

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      // 1. Initialize Flutter Local Notifications for rich heads-up alerts
      await _initLocalNotifications();

      // 2. Request notification permissions (POST_NOTIFICATIONS on Android 13+)
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint('NotificationService: Permission status: ${settings.authorizationStatus}');

      // 3. Automatically subscribe EVERY device/user to the global broadcast topics
      await _subscribeToBroadcastTopics();

      // 4. Register current device FCM token in Cloud Firestore
      // NOTE: Wrapped independently — Firestore PERMISSION_DENIED won't crash init.
      _registerDeviceToken().catchError((e) {
        debugPrint('NotificationService: Device token registration skipped (check Firestore rules): $e');
      });

      // 5. Setup Token refresh listener
      _fcm.onTokenRefresh.listen((newToken) {
        _registerDeviceToken(tokenOverride: newToken).catchError((e) {
          debugPrint('NotificationService: Token refresh registration skipped: $e');
        });
      });

      // 6. Foreground FCM message listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleForegroundMessage(message);
      });

      // 7. Background message tap listener (App was minimized)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationTap(message);
      });

      // 8. Terminated state launch notification check (App was completely closed)
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('NotificationService: Captured terminated launch message: ${initialMessage.data}');
        _pendingInitialMessage = initialMessage;
      }

      // 9. Real-time broadcast listener for foreground in-app synchronization
      // NOTE: Wrapped independently — Firestore PERMISSION_DENIED won't crash init.
      _startBroadcastListener();
    } catch (e) {
      debugPrint('NotificationService init error (continuing gracefully): $e');
    }
  }

  /// Sets up Flutter Local Notifications channel and tap callbacks
  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          try {
            final data = jsonDecode(payload) as Map<String, dynamic>;
            _navigateWithPayload(data);
          } catch (e) {
            debugPrint('Error parsing notification response payload: $e');
          }
        }
      },
    );

    // Create high-importance Android channel for heads-up alerts with sound
    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      const channel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );
      await androidPlugin.createNotificationChannel(channel);
    }
  }

  /// Subscribes every app installation to global broadcast topics
  Future<void> _subscribeToBroadcastTopics() async {
    if (kIsWeb) return;
    try {
      await _fcm.subscribeToTopic(topicAllUsers);
      await _fcm.subscribeToTopic(topicNewReleases);
      await _fcm.subscribeToTopic(topicNewEpisodes);
      await _fcm.subscribeToTopic(topicNewNovels);
      debugPrint('NotificationService: Subscribed to $topicAllUsers & related topics');
    } catch (e) {
      debugPrint('NotificationService: Could not subscribe to topics: $e');
    }
  }

  /// Syncs FCM token for current logged-in user into Firestore
  Future<void> syncUserDeviceToken(String userId) async {
    await _registerDeviceToken(userIdOverride: userId);
  }

  /// Saves or refreshes device token in Firestore `device_tokens` collection
  Future<void> _registerDeviceToken({String? tokenOverride, String? userIdOverride}) async {
    try {
      final token = tokenOverride ?? await _fcm.getToken();
      if (token == null || token.isEmpty) return;

      final platform = kIsWeb
          ? 'web'
          : Platform.isAndroid
              ? 'android'
              : Platform.isIOS
                  ? 'ios'
                  : 'desktop';

      final safeDocId = '${userIdOverride ?? "device"}_${token.substring(0, token.length.clamp(0, 30))}';

      await _firestore.collection('device_tokens').doc(safeDocId).set({
        'token': token,
        'userId': userIdOverride ?? 'guest',
        'platform': platform,
        'isSubscribed': true,
        'topics': [topicAllUsers, topicNewReleases, topicNewEpisodes, topicNewNovels],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('NotificationService: Device token registered for $safeDocId');
    } catch (e) {
      debugPrint('NotificationService: Error registering device token: $e');
    }
  }

  /// Listens to real-time broadcasts published while the app is active
  void _startBroadcastListener() {
    try {
      _broadcastSub?.cancel();
      _broadcastSub = _firestore
          .collection('broadcast_notifications')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots()
          .listen(
        (snapshot) {
          for (final docChange in snapshot.docChanges) {
            if (docChange.type == DocumentChangeType.added) {
              final data = docChange.doc.data();
              if (data == null) continue;

              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
              // Only trigger if published after this app session started (prevent stale playback)
              if (createdAt != null && createdAt.isAfter(_serviceStartTime.subtract(const Duration(seconds: 5)))) {
                final title = data['title'] as String? ?? 'New Release Available!';
                final body = data['body'] as String? ?? 'A new chapter has just been released.';
                final novelId = data['novelId'] as String?;
                final episodeId = data['episodeId'] as String?;

                _showLocalNotification(
                  title: title,
                  body: body,
                  payloadData: {
                    'type': data['type'] ?? 'new_episode',
                    'novelId': novelId,
                    'episodeId': episodeId,
                  },
                );
              }
            }
          }
        },
        onError: (e) {
          // Swallow PERMISSION_DENIED gracefully — fix Firestore rules to resolve permanently.
          debugPrint('NotificationService: Broadcast listener error (check Firestore rules): $e');
        },
      );
    } catch (e) {
      debugPrint('NotificationService broadcast listener error: $e');
    }
  }

  /// Displays native Android heads-up notification and in-app GetX banner
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required Map<String, dynamic> payloadData,
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await _localNotifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: jsonEncode(payloadData),
      );
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }

    // Also display sleek in-app GetX notification banner if in foreground
    _showInAppBanner(title: title, body: body, payloadData: payloadData);
  }

  void _showInAppBanner({
    required String title,
    required String body,
    required Map<String, dynamic> payloadData,
  }) {
    if (Get.context == null) return;

    Get.snackbar(
      title,
      body,
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFF1E293B),
      colorText: Colors.white,
      icon: const Icon(Icons.menu_book_rounded, color: Color(0xFF6366F1)),
      duration: const Duration(seconds: 5),
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
      mainButton: TextButton(
        onPressed: () {
          Get.back();
          _navigateWithPayload(payloadData);
        },
        child: const Text(
          'READ NOW',
          style: TextStyle(
            color: Color(0xFF818CF8),
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final title = message.notification?.title ?? message.data['title'] ?? 'New Release Available!';
    final body = message.notification?.body ?? message.data['body'] ?? 'A new episode is now live.';
    _showLocalNotification(
      title: title,
      body: body,
      payloadData: message.data,
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    _navigateWithPayload(message.data);
  }

  /// Core router: resolves target novel and lands the user DIRECTLY on that novel episode!
  Future<void> _navigateWithPayload(Map<String, dynamic> data) async {
    final type = data['type'] as String?;
    final novelId = data['novelId'] as String?;
    final episodeId = data['episodeId'] as String?;

    debugPrint('NotificationService: Direct landing for type: $type, novelId: $novelId, ep: $episodeId');
    if (novelId == null || novelId.isEmpty) return;

    await navigateToEpisode(novelId: novelId, episodeId: episodeId);
  }

  /// Directly navigates user to that novel episode. If episodeId is omitted,
  /// automatically discovers Chapter 1 so reader directly lands on the chapter reading screen.
  Future<void> navigateToEpisode({required String novelId, String? episodeId}) async {
    try {
      String? targetEpisodeId = episodeId;

      // If episodeId wasn't provided, discover the first chapter
      if (targetEpisodeId == null || targetEpisodeId.isEmpty) {
        targetEpisodeId = await _resolveFirstEpisodeId(novelId);
      }

      if (targetEpisodeId != null && targetEpisodeId.isNotEmpty) {
        debugPrint('NotificationService: Landing directly on reader: novel $novelId, ep $targetEpisodeId');
        Get.toNamed(AppRoutes.episodeReader(novelId, targetEpisodeId));
      } else {
        // Fallback to novel details if no episodes exist yet
        Get.toNamed(AppRoutes.novelDetails(novelId));
      }
    } catch (e) {
      debugPrint('NotificationService: Error navigating to episode: $e');
      Get.toNamed(AppRoutes.novelDetails(novelId));
    }
  }

  Future<String?> _resolveFirstEpisodeId(String novelId) async {
    try {
      if (Get.isRegistered<EpisodeUseCases>()) {
        final episodes = await Get.find<EpisodeUseCases>().getEpisodesForNovel(novelId, publishedOnly: true);
        if (episodes.isNotEmpty) {
          return episodes.first.id;
        }
      }
      // Firestore fallback
      final query = await _firestore
          .collection('episodes')
          .where('novelId', isEqualTo: novelId)
          .where('status', isEqualTo: 'published')
          .orderBy('episodeNumber')
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        return query.docs.first.id;
      }
    } catch (e) {
      debugPrint('NotificationService: Could not resolve first episode id: $e');
    }
    return null;
  }

  /// Consumes the pending launch message once the Splash page has established the root container.
  /// Guarantees 100% reliable direct landing without race conditions.
  Future<bool> consumePendingLaunchNotification() async {
    if (_pendingInitialMessage != null) {
      final msg = _pendingInitialMessage!;
      _pendingInitialMessage = null;
      debugPrint('NotificationService: Consuming pending launch message: ${msg.data}');
      // Brief tick to ensure root shell or auth route is mounted
      await Future.delayed(const Duration(milliseconds: 200));
      await _navigateWithPayload(msg.data);
      return true;
    }
    return false;
  }

  /// ================= BROADCAST PUBLISHING METHODS =================

  /// Called when Admin or Writer publishes an episode.
  /// Sends notification to EVERY person who installed the app.
  Future<void> broadcastNewEpisodeNotification({
    required String novelId,
    required String episodeId,
    required String novelTitle,
    required int episodeNumber,
    required String episodeTitle,
    String? writerName,
  }) async {
    final title = 'New Chapter Released! 📖';
    final body = '$novelTitle — Chapter $episodeNumber: $episodeTitle is now available!';

    await _dispatchBroadcast(
      type: 'new_episode',
      title: title,
      body: body,
      novelId: novelId,
      episodeId: episodeId,
      novelTitle: novelTitle,
      episodeNumber: episodeNumber,
      writerName: writerName,
    );
  }

  /// Called when Admin or Writer publishes a novel.
  /// Directly links to the initial episode / Chapter 1 for instant reading.
  Future<void> broadcastNewNovelNotification({
    required String novelId,
    required String novelTitle,
    required String writerName,
    String? firstEpisodeId,
  }) async {
    final title = 'New Novel Published! ✨';
    final body = '"$novelTitle" by $writerName is now live! Start reading Chapter 1.';

    await _dispatchBroadcast(
      type: 'new_episode',
      title: title,
      body: body,
      novelId: novelId,
      episodeId: firstEpisodeId,
      novelTitle: novelTitle,
      writerName: writerName,
    );
  }

  /// Writes broadcast payload to Firestore queue and sends push notification
  Future<void> _dispatchBroadcast({
    required String type,
    required String title,
    required String body,
    required String novelId,
    String? episodeId,
    String? novelTitle,
    int? episodeNumber,
    String? writerName,
  }) async {
    try {
      debugPrint('NotificationService: Broadcasting $type for novel: $novelId, ep: $episodeId');

      // 1. Create broadcast record in Firestore (triggers Cloud Functions / real-time listeners)
      await _firestore.collection('broadcast_notifications').add({
        'type': type,
        'title': title,
        'body': body,
        'novelId': novelId,
        'episodeId': episodeId,
        'novelTitle': novelTitle,
        'episodeNumber': episodeNumber,
        'writerName': writerName,
        'topic': topicAllUsers,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Also populate in-app notifications collection for persistence
      await _firestore.collection('notifications').add({
        'userId': 'all',
        'type': type,
        'title': title,
        'body': body,
        'novelId': novelId,
        'episodeId': episodeId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('NotificationService: Broadcast saved successfully');
    } catch (e) {
      debugPrint('NotificationService: Error creating broadcast document: $e');
    }
  }

  void dispose() {
    _broadcastSub?.cancel();
  }
}
