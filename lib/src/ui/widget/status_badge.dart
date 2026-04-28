import 'package:flutter/material.dart';

import '../../model/http_call.dart';
import '../theme/samseer_theme.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.call,
    this.compact = false,
    this.heroTag,
  });

  final SamseerHttpCall call;
  final bool compact;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final color = SamseerColors.forState(call.state);
    final label = switch (call.state) {
      SamseerCallState.loading => '···',
      SamseerCallState.error => 'ERR',
      _ => '${call.status ?? '—'}',
    };
    final isLoading = call.state == SamseerCallState.loading;

    Widget badge = Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8, vertical: compact ? 2 : 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1),
        boxShadow: isLoading
            ? null
            : [
                BoxShadow(
                  color: color.withValues(alpha: 0.18),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFeatures: const [FontFeature.tabularFigures()],
          fontWeight: FontWeight.w700,
          fontSize: compact ? 11 : 12,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );

    if (isLoading) {
      badge = _PulsingBadge(child: badge);
    }
    if (heroTag != null) {
      badge = Hero(
          tag: heroTag!,
          child: Material(color: Colors.transparent, child: badge));
    }
    return badge;
  }
}

class _PulsingBadge extends StatefulWidget {
  const _PulsingBadge({required this.child});
  final Widget child;

  @override
  State<_PulsingBadge> createState() => _PulsingBadgeState();
}

class _PulsingBadgeState extends State<_PulsingBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: 0.55 + 0.45 * _controller.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class MethodBadge extends StatelessWidget {
  const MethodBadge({super.key, required this.method});
  final String method;

  @override
  Widget build(BuildContext context) {
    final color = _methodColor(method);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        method.toUpperCase(),
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 11,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  static Color _methodColor(String m) {
    switch (m.toUpperCase()) {
      case 'GET':
        return const Color(0xFF22C55E);
      case 'POST':
        return const Color(0xFF3B82F6);
      case 'PUT':
        return const Color(0xFFF59E0B);
      case 'PATCH':
        return const Color(0xFF8B5CF6);
      case 'DELETE':
        return const Color(0xFFEF4444);
      case 'HEAD':
      case 'OPTIONS':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF6366F1);
    }
  }
}
