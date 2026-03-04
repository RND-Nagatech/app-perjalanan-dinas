import 'package:flutter/material.dart';

class CustomNoticeOverlay {
  static OverlayEntry show(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    final bgColor = isError ? const Color(0xFFB3261E) : const Color(0xFF0E7C7B);
    final media = MediaQuery.of(context);
    final bottomOffset = media.viewInsets.bottom > 0
        ? media.viewInsets.bottom + 12
        : media.padding.bottom + 86;

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
