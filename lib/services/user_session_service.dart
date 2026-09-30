import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service to persist and manage the local user session.
/// Enables offline access, especially for employees needing to access
/// their field diary and offline collection capabilities without internet.
class UserSessionService {
  static const String _keyUserId = 'user_session_id';
  static const String _keyRole = 'user_session_role';
  static const String _keyEmail = 'user_session_email';
  static const String _keyIsFirstTime = 'user_session_is_first_time';
  static const String _keyIsLoggedIn = 'user_session_is_logged_in';

  static String? _cachedUserId;
  static String? _cachedRole;
  static String? _cachedEmail;
  static bool _cachedIsFirstTime = false;
  static bool _cachedIsLoggedIn = false;

  /// Initialize cached session from SharedPreferences at app startup
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedUserId = prefs.getString(_keyUserId);
      _cachedRole = prefs.getString(_keyRole);
      _cachedEmail = prefs.getString(_keyEmail);
      _cachedIsFirstTime = prefs.getBool(_keyIsFirstTime) ?? false;
      _cachedIsLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    } catch (e) {
      debugPrint('Error initializing UserSessionService: $e');
    }
  }

  /// Save session details upon successful login or profile fetch
  static Future<void> saveSession({
    required String userId,
    required String role,
    String? email,
    bool isFirstTime = false,
  }) async {
    try {
      _cachedUserId = userId;
      _cachedRole = role;
      _cachedEmail = email;
      _cachedIsFirstTime = isFirstTime;
      _cachedIsLoggedIn = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserId, userId);
      await prefs.setString(_keyRole, role);
      if (email != null) {
        await prefs.setString(_keyEmail, email);
      } else {
        await prefs.remove(_keyEmail);
      }
      await prefs.setBool(_keyIsFirstTime, isFirstTime);
      await prefs.setBool(_keyIsLoggedIn, true);
    } catch (e) {
      debugPrint('Error saving user session: $e');
    }
  }

  /// Clear session when user explicitly logs out
  static Future<void> clearSession() async {
    try {
      _cachedUserId = null;
      _cachedRole = null;
      _cachedEmail = null;
      _cachedIsFirstTime = false;
      _cachedIsLoggedIn = false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUserId);
      await prefs.remove(_keyRole);
      await prefs.remove(_keyEmail);
      await prefs.remove(_keyIsFirstTime);
      await prefs.remove(_keyIsLoggedIn);
    } catch (e) {
      debugPrint('Error clearing user session: $e');
    }
  }

  /// Get currently active user ID (Supabase auth currentUser or local cache)
  static String? get currentUserId {
    try {
      return Supabase.instance.client.auth.currentUser?.id ?? _cachedUserId;
    } catch (_) {
      return _cachedUserId;
    }
  }

  /// Get cached user ID
  static String? get cachedUserId => _cachedUserId;

  /// Get user role ('employee', 'admin', 'user')
  static String? get currentUserRole => _cachedRole;

  /// Get user email
  static String? get currentUserEmail {
    try {
      return Supabase.instance.client.auth.currentUser?.email ?? _cachedEmail;
    } catch (_) {
      return _cachedEmail;
    }
  }

  /// Check whether the user is an employee or admin
  static bool get isEmployee {
    final role = _cachedRole?.toLowerCase().trim();
    return role == 'employee' || role == 'admin';
  }

  /// Check whether a user is logged in
  static bool get isLoggedIn {
    if (_cachedIsLoggedIn && _cachedUserId != null) return true;
    try {
      return Supabase.instance.client.auth.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  /// First time user flag
  static bool get isFirstTime => _cachedIsFirstTime;
}
