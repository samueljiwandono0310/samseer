import 'package:flutter/material.dart';

import '../../core/samseer_core.dart';
import '../../model/http_call.dart';
import '../theme/samseer_theme.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key, required this.core});
  final SamseerCore core;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: StreamBuilder<List<SamseerHttpCall>>(
        stream: core.storage.stream,
        initialData: core.storage.calls,
        builder: (context, snap) {
          final calls = snap.data ?? const <SamseerHttpCall>[];
          final totals = _Totals.from(calls);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _StatCard(
                    label: 'Total calls',
                    value: '${totals.total}',
                    color: Theme.of(context).colorScheme.primary,
                    icon: Icons.dns_outlined,
                  ),
                  _StatCard(
                    label: 'Success rate',
                    value: '${totals.successRate.toStringAsFixed(0)}%',
                    color: SamseerColors.success,
                    icon: Icons.check_circle_outline,
                  ),
                  _StatCard(
                    label: 'Avg duration',
                    value: totals.avgDuration,
                    color: SamseerColors.redirect,
                    icon: Icons.timer_outlined,
                  ),
                  _StatCard(
                    label: 'Errors',
                    value: '${totals.errors}',
                    color: SamseerColors.serverError,
                    icon: Icons.error_outline,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _Distribution(totals: totals),
            ],
          );
        },
      ),
    );
  }
}

class _Totals {
  _Totals({
    required this.total,
    required this.success,
    required this.redirect,
    required this.clientError,
    required this.serverError,
    required this.errors,
    required this.avgDuration,
    required this.successRate,
  });

  final int total;
  final int success;
  final int redirect;
  final int clientError;
  final int serverError;
  final int errors;
  final String avgDuration;
  final double successRate;

  static _Totals from(List<SamseerHttpCall> calls) {
    var success = 0, redirect = 0, clientErr = 0, serverErr = 0, errors = 0;
    var totalMs = 0;
    var counted = 0;
    for (final c in calls) {
      switch (c.state) {
        case SamseerCallState.success:
          success++;
        case SamseerCallState.redirect:
          redirect++;
        case SamseerCallState.clientError:
          clientErr++;
        case SamseerCallState.serverError:
          serverErr++;
        case SamseerCallState.error:
          errors++;
        case SamseerCallState.loading:
          break;
      }
      final d = c.duration;
      if (d != null) {
        totalMs += d.inMilliseconds;
        counted++;
      }
    }
    final avg = counted == 0 ? '—' : _fmtMs(totalMs ~/ counted);
    final rate = calls.isEmpty ? 0.0 : (success / calls.length) * 100;
    return _Totals(
      total: calls.length,
      success: success,
      redirect: redirect,
      clientError: clientErr,
      serverError: serverErr,
      errors: errors,
      avgDuration: avg,
      successRate: rate,
    );
  }

  static String _fmtMs(int ms) {
    if (ms < 1000) return '${ms}ms';
    return '${(ms / 1000).toStringAsFixed(2)}s';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
                color.withValues(alpha: 0.12), cs.surfaceContainerHigh),
            cs.surfaceContainerHigh,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.18),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _Distribution extends StatelessWidget {
  const _Distribution({required this.totals});
  final _Totals totals;

  @override
  Widget build(BuildContext context) {
    final segments = [
      _Seg('2xx', totals.success, SamseerColors.success),
      _Seg('3xx', totals.redirect, SamseerColors.redirect),
      _Seg('4xx', totals.clientError, SamseerColors.clientError),
      _Seg('5xx', totals.serverError, SamseerColors.serverError),
      _Seg('Err', totals.errors, SamseerColors.generalError),
    ];
    final total = segments.fold<int>(0, (a, b) => a + b.value);
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status distribution',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 12),
          if (total == 0)
            Text(
              'No data yet',
              style: TextStyle(color: cs.onSurfaceVariant),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 12,
                child: Row(
                  children: [
                    for (final s in segments)
                      if (s.value > 0)
                        Expanded(
                          flex: s.value,
                          child: Container(color: s.color),
                        ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              for (final s in segments)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration:
                          BoxDecoration(color: s.color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${s.label} · ${s.value}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Seg {
  _Seg(this.label, this.value, this.color);
  final String label;
  final int value;
  final Color color;
}
