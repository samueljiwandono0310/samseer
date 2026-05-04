import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:samseer/samseer.dart';

/// Bridges new HTTP calls captured by [Samseer] into native notifications via
/// `flutter_local_notifications`.
///
/// Tapping a notification opens the Samseer inspector. The same notification
/// id is reused so the system replaces the previous one rather than stacking.
class SamseerNotificationBridge {
  SamseerNotificationBridge({
    required Samseer samseer,
    required FlutterLocalNotificationsPlugin plugin,
    this.notificationId = 9999,
    this.androidChannelId = 'samseer',
    this.androidChannelName = 'Samseer HTTP calls',
  })  : _samseer = samseer,
        _plugin = plugin;

  final Samseer _samseer;
  final FlutterLocalNotificationsPlugin _plugin;
  final int notificationId;
  final String androidChannelId;
  final String androidChannelName;

  final Set<int> _notified = <int>{};
  StreamSubscription<List<SamseerHttpCall>>? _sub;

  void start() {
    _sub?.cancel();
    for (final call in _samseer.calls) {
      if (!call.loading) _notified.add(call.id);
    }
    _sub = _samseer.callsStream.listen(_onCalls);
  }

  /// Wire this into the plugin's `onDidReceiveNotificationResponse`.
  /// Returns `true` if the tap was a Samseer notification and the inspector
  /// was opened.
  bool handleTap(NotificationResponse response) {
    if (response.id != notificationId) return false;
    _samseer.showInspector();
    return true;
  }

  void _onCalls(List<SamseerHttpCall> calls) {
    for (final call in calls) {
      if (call.loading) continue;
      if (_notified.add(call.id)) _emit(call);
    }
    _notified.retainAll(calls.map((c) => c.id).toSet());
  }

  void _emit(SamseerHttpCall call) {
    final status = call.status?.toString() ?? (call.hasError ? 'ERR' : '-');
    final endpoint = call.endpoint.isEmpty ? call.uri : call.endpoint;
    final body = call.error?.message ?? call.uri;
    _plugin.show(
      notificationId,
      '[${call.method}] $status $endpoint',
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          androidChannelId,
          androidChannelName,
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentBadge: true,
          presentSound: false,
        ),
      ),
    );
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    _notified.clear();
  }
}
