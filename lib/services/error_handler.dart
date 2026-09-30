import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ErrorHandler {
  /// Parses any thrown error/exception and returns a human-readable, specific error string.
  static String parseError(dynamic error) {
    if (error == null) return "An unknown error occurred.";

    final errorStr = error.toString();

    // 1. Check for Network / Internet connectivity issues
    if (error is SocketException ||
        errorStr.contains("SocketException") ||
        errorStr.contains("ClientException") ||
        errorStr.contains("Failed host lookup") ||
        errorStr.contains("NetworkImage") ||
        errorStr.contains("Network error") ||
        errorStr.contains("connection refused") ||
        errorStr.contains("TimeoutException") ||
        errorStr.contains("handshake failed")) {
      return "Network Error: No internet connection. Please check your connection and try again.";
    }

    // 2. Supabase Auth Exceptions
    if (error is AuthException) {
      if (error.message.contains("Invalid login credentials")) {
        return "Invalid credentials. Please check your email and password.";
      }
      if (error.message.contains("Email not confirmed")) {
        return "Email verification required. Please check your inbox.";
      }
      if (error.message.contains("User already registered")) {
        return "An account with this email address already exists.";
      }
      return "Authentication Error: ${error.message}";
    }

    // 3. Supabase Postgrest (Database) Exceptions
    if (error is PostgrestException) {
      return "Database Error: ${error.message}${error.code != null ? ' (Code: ${error.code})' : ''}";
    }

    // 4. Format generic exceptions neatly
    String cleanMessage = errorStr;
    if (cleanMessage.startsWith("Exception: ")) {
      cleanMessage = cleanMessage.replaceFirst("Exception: ", "");
    }
    return "Error: $cleanMessage";
  }

  /// Displays a snackbar showing the parsed error message.
  static void showError(BuildContext context, dynamic error, {String? customTitle}) {
    if (!context.mounted) return;
    
    final message = parseError(error);
    final displayMsg = customTitle != null ? "$customTitle: $message" : message;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                displayMsg,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
