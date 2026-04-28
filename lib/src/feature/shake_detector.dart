import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Detects device shakes using the accelerometer. When a shake exceeding the
/// [threshold] is detected, [onShake] is invoked.
class ShakeDetector {
  ShakeDetector({
    required this.onShake,
    this.threshold = 20,
    this.cooldown = const Duration(milliseconds: 1500),
  });

  final VoidCallback onShake;
  final double threshold;
  final Duration cooldown;

  StreamSubscription<UserAccelerometerEvent>? _sub;
  DateTime _lastShake = DateTime.fromMillisecondsSinceEpoch(0);

  void start() {
    if (_sub != null) return;
    try {
      _sub = userAccelerometerEventStream(
        samplingPeriod: const Duration(milliseconds: 200),
      ).listen((event) {
        final magnitude =
            sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
        if (magnitude > threshold) {
          final now = DateTime.now();
          if (now.difference(_lastShake) > cooldown) {
            _lastShake = now;
            onShake();
          }
        }
      }, onError: (_) {
        // Sensors are not available on all platforms (web, desktop). Ignore.
      });
    } catch (_) {
      // Platform doesn't support sensors (e.g., tests, web, desktop).
      _sub = null;
    }
  }

  void stop() {
    try {
      _sub?.cancel();
    } catch (_) {
      // Ignore — sensor channel may already be disposed.
    }
    _sub = null;
  }
}
