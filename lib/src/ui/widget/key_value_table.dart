import 'package:flutter/material.dart';

import '../theme/samseer_theme.dart';

class KeyValueTable extends StatelessWidget {
  const KeyValueTable({super.key, required this.entries, this.emptyLabel = 'Empty'});

  final Map<String, dynamic> entries;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          emptyLabel,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }
    final keys = entries.keys.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < keys.length; i++) ...[
          if (i > 0) const Divider(height: 1),
          _Row(name: keys[i], value: '${entries[keys[i]]}'),
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.name, required this.value});
  final String name;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(value, style: SamseerTheme.mono(context, size: 12)),
          ),
        ],
      ),
    );
  }
}
