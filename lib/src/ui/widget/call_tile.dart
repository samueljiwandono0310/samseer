import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../model/http_call.dart';
import 'status_badge.dart';

class CallTile extends StatelessWidget {
  const CallTile({super.key, required this.call, required this.onTap});
  final SamseerHttpCall call;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm:ss').format(call.createdAt);
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  MethodBadge(method: call.method),
                  const SizedBox(width: 6),
                  StatusBadge(call: call),
                  const Spacer(),
                  Text(
                    time,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 11,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                call.endpoint,
                style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                call.server,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _Pill(icon: Icons.timer_outlined, label: _formatDuration(call.duration)),
                  const SizedBox(width: 6),
                  _Pill(icon: Icons.cloud_download_outlined, label: _formatBytes(call.response?.size)),
                  const SizedBox(width: 6),
                  _Pill(icon: Icons.api_outlined, label: call.client),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDuration(Duration? d) {
    if (d == null) return '—';
    final ms = d.inMilliseconds;
    if (ms < 1000) return '${ms}ms';
    return '${(ms / 1000).toStringAsFixed(2)}s';
  }

  static String _formatBytes(int? bytes) {
    if (bytes == null) return '—';
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(2)}MB';
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
