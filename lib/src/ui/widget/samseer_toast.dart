import 'dart:async';

import 'package:flutter/material.dart';

enum SamseerToastVariant { neutral, success, warning, error }

/// Top-of-screen notification banner. Slides down from above the status bar,
/// auto-dismisses, and stacks gracefully when shown rapidly in succession.
class SamseerToast {
  static OverlayEntry? _current;
  static Timer? _dismissTimer;

  static void show(
    BuildContext context,
    String message, {
    String? subtitle,
    IconData? icon,
    SamseerToastVariant variant = SamseerToastVariant.neutral,
    Duration duration = const Duration(milliseconds: 2600),
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _dismiss(animated: false);

    final entry = OverlayEntry(
      builder: (_) => _ToastHost(
        message: message,
        subtitle: subtitle,
        icon: icon ?? _defaultIcon(variant),
        variant: variant,
        onDismissed: _dismiss,
      ),
    );
    _current = entry;
    overlay.insert(entry);

    _dismissTimer = Timer(duration, () => _dismiss());
  }

  static void _dismiss({bool animated = true}) {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    final entry = _current;
    _current = null;
    if (entry == null) return;
    if (!animated) {
      entry.remove();
      return;
    }
    // Let the host widget run its exit animation; it removes itself.
    _ToastHost._dismiss(entry);
  }

  static IconData _defaultIcon(SamseerToastVariant v) {
    switch (v) {
      case SamseerToastVariant.success:
        return Icons.check_circle_rounded;
      case SamseerToastVariant.warning:
        return Icons.warning_amber_rounded;
      case SamseerToastVariant.error:
        return Icons.error_rounded;
      case SamseerToastVariant.neutral:
        return Icons.info_rounded;
    }
  }
}

class _ToastHost extends StatefulWidget {
  const _ToastHost({
    required this.message,
    required this.subtitle,
    required this.icon,
    required this.variant,
    required this.onDismissed,
  });

  final String message;
  final String? subtitle;
  final IconData icon;
  final SamseerToastVariant variant;
  final VoidCallback onDismissed;

  static final Map<OverlayEntry, _ToastHostState> _hosts = {};

  static void _dismiss(OverlayEntry entry) {
    final state = _hosts[entry];
    if (state == null) {
      entry.remove();
      return;
    }
    state._exit(entry);
  }

  @override
  State<_ToastHost> createState() => _ToastHostState();
}

class _ToastHostState extends State<_ToastHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    reverseDuration: const Duration(milliseconds: 220),
  );

  late final Animation<double> _slide = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  OverlayEntry? _ownEntry;

  @override
  void initState() {
    super.initState();
    // Defer registration until the first frame so we have an OverlayEntry ref.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ownEntry ??= _findOwnEntry();
      if (_ownEntry != null) {
        _ToastHost._hosts[_ownEntry!] = this;
      }
    });
    _controller.forward();
  }

  OverlayEntry? _findOwnEntry() {
    // The static dismisser holds a ref already; we don't need to search.
    return SamseerToast._current;
  }

  Future<void> _exit(OverlayEntry entry) async {
    if (!mounted) {
      entry.remove();
      return;
    }
    await _controller.reverse();
    if (entry.mounted) entry.remove();
    _ToastHost._hosts.remove(entry);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final (bg, fg, accent) = _palette(cs);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: AnimatedBuilder(
          animation: _slide,
          builder: (context, child) {
            return Opacity(
              opacity: _slide.value,
              child: Transform.translate(
                offset: Offset(0, (1 - _slide.value) * -40),
                child: child,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => SamseerToast._dismiss(),
                child: Ink(
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: accent.withValues(alpha: 0.18)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(widget.icon, size: 18, color: accent),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.message,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: fg,
                                  fontWeight: FontWeight.w600,
                                  height: 1.25,
                                ),
                              ),
                              if (widget.subtitle != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  widget.subtitle!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: fg.withValues(alpha: 0.72),
                                  ),
                                ),
                              ],
                            ],
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

  (Color bg, Color fg, Color accent) _palette(ColorScheme cs) {
    switch (widget.variant) {
      case SamseerToastVariant.success:
        return (
          cs.surfaceContainerHighest,
          cs.onSurface,
          const Color(0xFF22C55E)
        );
      case SamseerToastVariant.warning:
        return (
          cs.surfaceContainerHighest,
          cs.onSurface,
          const Color(0xFFF59E0B)
        );
      case SamseerToastVariant.error:
        return (
          cs.surfaceContainerHighest,
          cs.onSurface,
          const Color(0xFFEF4444)
        );
      case SamseerToastVariant.neutral:
        return (cs.surfaceContainerHighest, cs.onSurface, cs.primary);
    }
  }
}
