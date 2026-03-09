import 'package:flutter/material.dart';

class CustomNoticeOverlay {
  static OverlayEntry show(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    final bgColor = isError ? const Color(0xFFB3261E) : const Color(0xFF0E7C7B);
    final media = MediaQuery.of(context);
    // If keyboard is visible, position above keyboard. Otherwise position
    // above the bottom navigation bar (use the material constant for default
    // bottom navigation height and include safe area padding).
    final keyboardInset = media.viewInsets.bottom;
    final safeBottom = media.padding.bottom;
    const defaultBottomNavHeight = kBottomNavigationBarHeight; // 56.0
    // When keyboard visible, keep above keyboard with a small margin.
    // Otherwise position the notice slightly above the bottom navigation —
    // reduce the gap so it appears closer to the nav (but still above it).
    final bottomOffset = (keyboardInset > 0)
        ? keyboardInset + 12
        : (safeBottom + defaultBottomNavHeight - 8.5).clamp(
            8.5,
            double.infinity,
          );

    final entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          bottom: bottomOffset,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 1, end: 0),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 32 * value),
                  child: Opacity(opacity: 1 - value, child: child),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.18),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      isError
                          ? Icons.error_outline
                          : Icons.check_circle_outline,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(entry);
    return entry;
  }
}
