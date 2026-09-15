import 'package:flutter/material.dart';

/// Global top-positioned animated notification utility.
/// Usage:
///   AppNotify.success(context, 'Saved successfully!');
///   AppNotify.error(context, 'Something went wrong.');
class AppNotify {
  static OverlayEntry? _currentEntry;

  static void success(BuildContext context, String message) {
    _show(context, message, isError: false);
  }

  static void error(BuildContext context, String message) {
    _show(context, message, isError: true);
  }

  static void _show(BuildContext context, String message,
      {required bool isError}) {
    // Dismiss any existing notification first
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) => _TopNotificationWidget(
        message: message,
        isError: isError,
        onDismiss: () {
          entry.remove();
          if (_currentEntry == entry) _currentEntry = null;
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }
}

class _TopNotificationWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const _TopNotificationWidget({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  @override
  State<_TopNotificationWidget> createState() =>
      _TopNotificationWidgetState();
}

class _TopNotificationWidgetState extends State<_TopNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    // Auto-dismiss after 3.5 seconds
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) _dismiss();
    });
  }

  void _dismiss() async {
    await _controller.reverse();
    if (mounted) widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color bgColor =
        widget.isError ? const Color(0xFFC0392B) : const Color(0xFF27AE60);
    final IconData icon =
        widget.isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: _dismiss,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: bgColor.withOpacity(0.45),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(icon, color: Colors.white, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _dismiss,
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white70, size: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
