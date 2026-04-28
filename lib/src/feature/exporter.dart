import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../model/http_call.dart';

class Exporter {
  /// Save calls to a JSON file in the temp directory and trigger the system
  /// share sheet. Returns the file path on success.
  static Future<String?> shareAsJson(
    List<SamseerHttpCall> calls, {
    Rect? sharePositionOrigin,
  }) async {
    if (calls.isEmpty) return null;
    final dir = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/samseer_export_$ts.json');
    final encoder = const JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(calls.map((c) => c.toJson()).toList()));
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Samseer HTTP export — ${calls.length} calls',
      sharePositionOrigin: sharePositionOrigin,
    );
    return file.path;
  }

  static Future<void> shareCurl(SamseerHttpCall call, {Rect? sharePositionOrigin}) async {
    await Share.share(buildCurl(call), sharePositionOrigin: sharePositionOrigin);
  }

  /// Share a full human-readable dump of the call (request + response).
  static Future<void> shareCallDump(
    SamseerHttpCall call, {
    Rect? sharePositionOrigin,
  }) async {
    await Share.share(
      buildCallDump(call),
      subject: '${call.method} ${call.endpoint}',
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  /// Compute the global rect of the widget at [context] — needed for iPad
  /// share popover anchoring. Returns null if the render box isn't available.
  static Rect? originFor(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  /// Build a complete, paste-ready dump of the call: URL, method, status,
  /// timing, request headers/body, response headers/body, and cURL command.
  /// Format is plain text — friendly for Slack, Discord, GitHub issues.
  static String buildCallDump(SamseerHttpCall call) {
    final b = StringBuffer();
    final encoder = const JsonEncoder.withIndent('  ');

    b
      ..writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
      ..writeln('  ${call.method} ${call.uri}')
      ..writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
      ..writeln('Client      : ${call.client}')
      ..writeln('Status      : ${call.response?.status ?? (call.hasError ? "ERROR" : "pending")}')
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
        ..writeln('Error: ${call.error?.message ?? call.error?.error ?? "unknown"}')
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
}
