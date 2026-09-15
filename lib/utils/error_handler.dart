import 'package:supabase_flutter/supabase_flutter.dart';

class ErrorHandler {
  static String getErrorMessage(Object error) {
    if (error is AuthWeakPasswordException) {
      return error.message.isNotEmpty
          ? error.message
          : 'Password must be at least 6 characters long.';
    }

    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('weak password') || msg.contains('at least 6 characters')) {
        return 'Password must be at least 6 characters long.';
      }
      if (msg.contains('already registered') || msg.contains('already exists') || error.code == 'user_already_exists') {
        return 'This email is already registered. Please sign in instead.';
      }
      if (msg.contains('email not confirmed')) {
        return 'Email not confirmed. Please verify your email or disable confirmation.';
      }
      if (msg.contains('invalid login credentials') || msg.contains('invalid_credentials')) {
        return 'Incorrect email or password. Please check and try again.';
      }
      return error.message;
    }

    if (error is PostgrestException) {
      // 521: Web Server Is Down (usually means Supabase project is paused)
      // 503: Service Unavailable
      if (error.code == '521' || error.message.contains('521') || error.message.contains('503')) {
        return 'The database is currently paused. Please try again in a few seconds...';
      }
      return error.message;
    }
    
    final errStr = error.toString();
    if (errStr.contains('AuthWeakPasswordException') || errStr.contains('Password should be at least')) {
      return 'Password must be at least 6 characters long.';
    }

    if (errStr.contains('user_already_exists') || errStr.toLowerCase().contains('already registered')) {
      return 'This email is already registered. Please sign in instead.';
    }

    if (errStr.contains('SocketException') || errStr.contains('Failed host lookup')) {
      return 'No internet connection. Please check your network.';
    }
    
    if (errStr.contains('521') || errStr.contains('503')) {
      return 'The database is currently paused. Please try again in a few seconds...';
    }

    return errStr;
  }
}
