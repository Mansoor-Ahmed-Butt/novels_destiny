import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  RemoteMessage? _pendingInitialMessage;

  Future<void> init() async {
    try {
      // 1. Request notification permissions
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('NotificationService: Permission status: ${settings.authorizationStatus}');

      // 2. Setup Foreground notification listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleForegroundMessage(message);
      });

      // 3. Setup Background notification tap listener
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationTap(message);
      });

      // 4. Check for Terminated-state launch notification
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        _pendingInitialMessage = initialMessage;
      }

      // 5. Setup Token refresh listener
      _fcm.onTokenRefresh.listen((newToken) {
        _updateDeviceToken(newToken);
      });
    } catch (e) {
      debugPrint('NotificationService init error (continuing): $e');
    }
  }

  /// Syncs FCM token for current logged-in user into Firestore
  Future<void> syncUserDeviceToken(String userId) async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _saveDeviceToken(userId: userId, token: token);
      }
    } catch (e) {
      debugPrint('Error syncing FCM token: $e');
    }
  }

  Future<void> _saveDeviceToken({required String userId, required String token}) async {
    try {
      final platform = kIsWeb
          ? 'web'
          : Platform.isAndroid
              ? 'android'
              : Platform.isIOS
                  ? 'ios'
                  : 'desktop';

      // Token doc id = base64 or safe hash of token or token itself truncated
      final docId = '${userId}_${token.substring(0, token.length.clamp(0, 30))}';

      await _firestore.collection('device_tokens').doc(docId).set({
        'userId': userId,
        'token': token,
        'platform': platform,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('Device token saved for user: $userId');
    } catch (e) {
      debugPrint('Error saving device token: $e');
    }
  }

  Future<void> _updateDeviceToken(String newToken) async {
    try {
      // Find tokens with old token or update
      debugPrint('Device token refreshed: $newToken');
    } catch (e) {
      debugPrint('Error updating device token: $e');
    }
  }

  /// Check and execute any pending terminated launch message once the router is ready
  void handlePendingLaunchNotification() {
    if (_pendingInitialMessage != null) {
      final msg = _pendingInitialMessage!;
      _pendingInitialMessage = null;
      Future.delayed(const Duration(milliseconds: 600), () {
        _handleNotificationTap(msg);
      });
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final title = message.notification?.title ?? message.data['title'] ?? 'New Notification';
    final body = message.notification?.body ?? message.data['body'] ?? '';

    Get.snackbar(
      title,
      body,
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFF1E293B),
      colorText: Colors.white,
      icon: const Icon(Icons.notifications_active_rounded, color: Color(0xFF6366F1)),
      duration: const Duration(seconds: 4),
      mainButton: TextButton(
        onPressed: () {
          Get.back();
          _handleNotificationTap(message);
        },
        child: const Text(
          'VIEW',
          style: TextStyle(color: Color(0xFF818CF8), fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] as String?;
    final novelId = data['novelId'] as String?;
    final episodeId = data['episodeId'] as String?;

    debugPrint('NotificationService: Handling tap for type: $type, novelId: $novelId, ep: $episodeId');

    if (type == 'new_episode' && novelId != null && episodeId != null) {
      Get.toNamed(AppRoutes.episodeReader(novelId, episodeId));
    } else if (type == 'novel' && novelId != null) {
      Get.toNamed(AppRoutes.novelDetails(novelId));
    }
  }
}
