import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/user_model.dart';
import '../constants/app_constants.dart';

class SessionService {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  /// Saves the authenticated user session locally
  Future<void> saveUserSession(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(user.toJson());
      await prefs.setString(AppConstants.userSessionStorageKey, userJson);
      debugPrint('SessionService: User session saved for ${user.email}');
    } catch (e) {
      debugPrint('SessionService: Error saving session: $e');
    }
  }

  /// Retrieves the persisted user session if one exists
  Future<UserModel?> getSavedUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(AppConstants.userSessionStorageKey);
      if (userJson != null && userJson.isNotEmpty) {
        final Map<String, dynamic> map = jsonDecode(userJson);
        final user = UserModel.fromJson(map);
        debugPrint('SessionService: Restored active session for ${user.email} (${user.role.name})');
        return user;
      }
    } catch (e) {
      debugPrint('SessionService: Error retrieving saved session: $e');
    }
    return null;
  }

  /// Clears the saved user session on sign out
  Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.userSessionStorageKey);
      debugPrint('SessionService: Active session cleared');
    } catch (e) {
      debugPrint('SessionService: Error clearing session: $e');
    }
  }
}
