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

    final errLower = errStr.toLowerCase();

    // Catch all network-related exceptions (ClientException, SocketException, Connection reset, etc.)
    if (errLower.contains('socketexception') ||
        errLower.contains('failed host lookup') ||
        errLower.contains('connection reset') ||
        errLower.contains('connection refused') ||
        errLower.contains('connection closed') ||
        errLower.contains('clientexception') ||
        errLower.contains('network is unreachable') ||
        errLower.contains('handshakeexception') ||
        errLower.contains('timeoutexception') ||
        errLower.contains('software caused connection abort') ||
        errLower.contains('xmlhttprequest error') ||
        errLower.contains('os error')) {
      return 'Unable to connect. Please check your internet connection.';
    }
    
    if (errStr.contains('521') || errStr.contains('503')) {
      return 'The database is currently paused. Please try again in a few seconds...';
    }

    // Never leak raw technical URLs, query parameters, or stack traces
    if (errLower.contains('uri=https://') || errLower.contains('supabase.co')) {
      return 'Unable to connect to the server. Please check your connection and try again.';
    }

    return errStr;
  }
}
