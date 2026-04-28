import 'dart:convert';

import '../model/http_call.dart';

class Exporter {
  /// Build a pretty-printed JSON array of every call — suitable for clipboard
  /// or paste-into-file workflows.
  static String buildJsonExport(List<SamseerHttpCall> calls) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(calls.map((c) => c.toJson()).toList());
  }

  /// Build a complete, paste-ready dump of the call: URL, method, status,
  /// timing, request headers/body, response headers/body, and cURL command.
  /// Format is plain text — friendly for Slack, Discord, GitHub issues.
  static String buildCallDump(SamseerHttpCall call) {
    final b = StringBuffer();
    const encoder = JsonEncoder.withIndent('  ');

    b
      ..writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
      ..writeln('  ${call.method} ${call.uri}')
      ..writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
      ..writeln('Client      : ${call.client}')
      ..writeln(
          'Status      : ${call.response?.status ?? (call.hasError ? "ERROR" : "pending")}')
      ..writeln('Duration    : ${_fmtDuration(call.duration)}')
      ..writeln('Started     : ${call.createdAt.toIso8601String()}')
      ..writeln('Secure      : ${call.secure ? "TLS" : "plain"}')
      ..writeln();

    b.writeln('── REQUEST ──────────────────────────────────');
    if (call.request.queryParameters.isNotEmpty) {
      b.writeln('Query:');
      call.request.queryParameters.forEach((k, v) => b.writeln('  $k = $v'));
    }
    if (call.request.headers.isNotEmpty) {
      b.writeln('Headers:');
      call.request.headers.forEach((k, v) => b.writeln('  $k: $v'));
    }
    if (call.request.body != null) {
      b
        ..writeln('Body:')
        ..writeln(_formatBody(call.request.body, encoder));
    }
    b.writeln();

    b.writeln('── RESPONSE ─────────────────────────────────');
    final response = call.response;
    if (response == null && call.error != null) {
      b
        ..writeln(
            'Error: ${call.error?.message ?? call.error?.error ?? "unknown"}')
        ..writeln();
    } else if (response != null) {
      b.writeln('Status: ${response.status}');
      if (response.headers.isNotEmpty) {
        b.writeln('Headers:');
        response.headers.forEach((k, v) => b.writeln('  $k: $v'));
      }
      if (response.body != null) {
        b
          ..writeln('Body:')
          ..writeln(_formatBody(response.body, encoder));
      }
      b.writeln();
    } else {
      b.writeln('(no response yet)');
    }

    b
      ..writeln('── cURL ─────────────────────────────────────')
      ..writeln(buildCurl(call));

    return b.toString();
  }

  /// Build a cURL representation of the given call.
  static String buildCurl(SamseerHttpCall call) {
    final buffer = StringBuffer('curl -X ${call.method.toUpperCase()}');
    call.request.headers.forEach((key, value) {
      buffer.write(" -H '$key: $value'");
    });
    final body = call.request.body;
    if (body != null) {
      final encoded = body is String ? body : json.encode(body);
      final escaped = encoded.replaceAll("'", "'\\''");
      buffer.write(" -d '$escaped'");
    }
    buffer.write(" '${call.uri}'");
    return buffer.toString();
  }

  /// Human-readable byte size — used by callers to show "Copied (12.4 KB)".
  static String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
  }

  static String _formatBody(dynamic body, JsonEncoder encoder) {
    if (body == null) return '';
    if (body is Map || body is List) {
      try {
        return encoder.convert(body);
      } catch (_) {
        return body.toString();
      }
    }
    if (body is String) {
      final trimmed = body.trim();
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        try {
          return encoder.convert(json.decode(trimmed));
        } catch (_) {}
      }
      return body;
    }
    return body.toString();
  }

  static String _fmtDuration(Duration? d) {
    if (d == null) return '—';
    final ms = d.inMilliseconds;
    if (ms < 1000) return '${ms}ms';
    return '${(ms / 1000).toStringAsFixed(2)}s';
  }
}
