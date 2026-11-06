import 'package:flutter/material.dart';

enum TopToastType { success, error, info }

class TopToast {
  static void showSuccess(BuildContext context, String message, {Duration duration = const Duration(seconds: 4)}) {
    show(context, message: message, type: TopToastType.success, duration: duration);
  }

  static void showError(BuildContext context, String message, {Duration duration = const Duration(seconds: 4)}) {
    show(context, message: message, type: TopToastType.error, duration: duration);
  }

  static void showInfo(BuildContext context, String message, {Duration duration = const Duration(seconds: 4)}) {
    show(context, message: message, type: TopToastType.info, duration: duration);
  }

  static void show(
    BuildContext context, {
    required String message,
    TopToastType type = TopToastType.success,
    Duration duration = const Duration(seconds: 4),
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) => _TopToastWidget(
        message: message,
        type: type,
        onDismissed: () {
          if (entry.mounted) {
            entry.remove();
          }
        },
        duration: duration,
      ),
    );

    overlay.insert(entry);
  }
}

class _TopToastWidget extends StatefulWidget {
  final String message;
  final TopToastType type;
  final VoidCallback onDismissed;
  final Duration duration;

  const _TopToastWidget({
    required this.message,
    required this.type,
    required this.onDismissed,
    required this.duration,
  });

  @override
  State<_TopToastWidget> createState() => _TopToastWidgetState();
}

class _TopToastWidgetState extends State<_TopToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    Color bg;
    Color border;
    Color iconColor;
    Color textColor;
    IconData icon;

    switch (widget.type) {
      case TopToastType.success:
        bg = const Color(0xFF15803D); // Verde vibrante de confirmação
        border = const Color(0xFF22C55E);
        iconColor = Colors.white;
        textColor = Colors.white;
        icon = Icons.check_circle_rounded;
        break;
      case TopToastType.error:
        bg = const Color(0xFFB91C1C);
        border = const Color(0xFFEF4444);
        iconColor = Colors.white;
        textColor = Colors.white;
        icon = Icons.error_rounded;
        break;
      case TopToastType.info:
        bg = const Color(0xFF1D4ED8);
        border = const Color(0xFF3B82F6);
        iconColor = Colors.white;
        textColor = Colors.white;
        icon = Icons.info_rounded;
        break;
    }

    return Positioned(
      top: topPadding + 14,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _offsetAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: GestureDetector(
              onTap: _dismiss,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: border, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          offset: const Offset(0, 8),
                          blurRadius: 20,
                        ),
                        BoxShadow(
                          color: bg.withValues(alpha: 0.35),
                          offset: const Offset(0, 4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: iconColor, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.message,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _dismiss,
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.white.withValues(alpha: 0.75),
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
