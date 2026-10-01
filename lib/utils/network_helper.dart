import 'dart:async';

/// Retries an asynchronous operation with progressive backoff.
/// Particularly useful for transient network errors like "Connection reset by peer",
/// socket drops, and server timeouts.
Future<T> retryOperation<T>(
  Future<T> Function() operation, {
  int maxRetries = 3,
  Duration initialDelay = const Duration(milliseconds: 600),
}) async {
  int attempt = 0;
  while (true) {
    attempt++;
    try {
      return await operation();
    } catch (e) {
      final err = e.toString().toLowerCase();
      final isNetworkGlitch = err.contains('connection reset') ||
          err.contains('connection closed') ||
          err.contains('connection refused') ||
          err.contains('clientexception') ||
          err.contains('socketexception') ||
          err.contains('failed host lookup') ||
          err.contains('handshakeexception') ||
          err.contains('timeoutexception') ||
          err.contains('os error') ||
          err.contains('software caused connection abort') ||
          err.contains('503') ||
          err.contains('521');

      if (!isNetworkGlitch || attempt >= maxRetries) {
        rethrow;
      }
      await Future.delayed(initialDelay * attempt);
    }
  }
}
