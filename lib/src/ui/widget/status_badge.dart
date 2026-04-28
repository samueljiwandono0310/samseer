import 'package:flutter/material.dart';

import '../../model/http_call.dart';
import '../theme/samseer_theme.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.call, this.compact = false});
  final SamseerHttpCall call;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = SamseerColors.forState(call.state);
    final label = switch (call.state) {
      SamseerCallState.loading => '···',
      SamseerCallState.error => 'ERR',
      _ => '${call.status ?? '—'}',
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: compact ? 2 : 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
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
