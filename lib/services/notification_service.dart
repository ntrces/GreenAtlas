import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Comprehensive Mobile Notification Service
/// Handles System Notification Permissions, Preferences, and Error Boundaries.
class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Requests Mobile System Notification Permission from the Operating System
  Future<bool> requestNotificationPermission(BuildContext context) async {
    try {
      final status = await Permission.notification.status;

      if (status.isGranted) {
        return true;
      }

      // Request permission from the mobile OS
      final result = await Permission.notification.request();

      if (result.isGranted) {
        return true;
      } else if (result.isPermanentlyDenied) {
        if (context.mounted) {
          _showPermissionDeniedDialog(context);
        }
        return false;
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Notification permission is required to receive mobile alerts."),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return false;
      }
    } on PlatformException catch (e) {
      debugPrint("Platform error requesting notification permission: $e");
      if (context.mounted) {
        _showErrorSnackBar(context, "Permission error: ${e.message ?? e.code}");
      }
      return false;
    } catch (e) {
      debugPrint("Unexpected error requesting notification permission: $e");
      if (context.mounted) {
        _showErrorSnackBar(context, "Unable to request notification permission: $e");
      }
      return false;
    }
  }

  /// Updates Push Notification preference in Supabase & validates OS permission
  Future<bool> setPushNotificationsEnabled(BuildContext context, bool enabled) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _showErrorSnackBar(context, "You must be logged in to change notification settings.");
      return false;
    }

    try {
      if (enabled) {
        // Request mobile OS permission first when enabling
        final granted = await requestNotificationPermission(context);
        if (!granted) {
          return false;
        }
      }

      // Save preference to Supabase database
      await _supabase
          .from('profiles')
          .update({'push_notifications_enabled': enabled})
          .eq('id', user.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(enabled ? "Mobile push notifications enabled!" : "Push notifications disabled."),
            duration: const Duration(milliseconds: 1500),
            backgroundColor: const Color(0xFF5D7A5D),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return enabled;
    } on PostgrestException catch (e) {
      debugPrint("Database error updating notification preference: ${e.message}");
      if (context.mounted) {
        _showErrorSnackBar(context, "Database error: ${e.message}");
      }
      return !enabled; // Revert switch state
    } on AuthException catch (e) {
      debugPrint("Auth error updating notification preference: ${e.message}");
      if (context.mounted) {
        _showErrorSnackBar(context, "Authentication error: ${e.message}");
      }
      return !enabled;
    } catch (e) {
      debugPrint("Unexpected error updating notification preference: $e");
      if (context.mounted) {
        _showErrorSnackBar(context, "Failed to update notification settings: $e");
      }
      return !enabled;
    }
  }

  /// Dialog shown when system notification permissions are permanently denied
  void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.notifications_off_outlined, color: Colors.orange, size: 24),
              SizedBox(width: 8),
              Text("Notification Access", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            "Notification permissions are permanently disabled in your device settings. Please open App Settings and turn on Notifications to receive mobile alerts.",
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await openAppSettings();
                } catch (e) {
                  debugPrint("Error opening app settings: $e");
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5D7A5D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("OPEN SETTINGS"),
            ),
          ],
        );
      },
    );
  }

  /// Helper to display safety error SnackBar
  void _showErrorSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
