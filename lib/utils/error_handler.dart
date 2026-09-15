import 'package:supabase_flutter/supabase_flutter.dart';

class ErrorHandler {
  static String getErrorMessage(Object error) {
    if (error is PostgrestException) {
      // 521: Web Server Is Down (usually means Supabase project is paused)
      // 503: Service Unavailable
      if (error.code == '521' || error.message.contains('521') || error.message.contains('503')) {
        return 'The database is currently paused . Please try again in a few seconds...';
      }
      return error.message;
    }
    
    final errStr = error.toString();
    if (errStr.contains('SocketException') || errStr.contains('Failed host lookup')) {
      return 'No internet connection. Please check your network.';
    }
    
    if (errStr.contains('521') || errStr.contains('503')) {
      return 'The database is currently paused . Please try again in a few seconds...';
    }

    return errStr;
  }
}
