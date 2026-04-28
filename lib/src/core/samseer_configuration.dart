import 'package:flutter/material.dart';

@immutable
class SamseerConfiguration {
  const SamseerConfiguration({
    this.maxCallsCount = 1000,
    this.showInspectorOnShake = true,
    this.showFloatingBubble = false,
    this.themeMode = ThemeMode.system,
    this.directionality,
    this.shakeThreshold = 20,
  });

  /// Max number of HTTP calls to keep in memory. Older calls are evicted FIFO.
  final int maxCallsCount;

  /// Whether shaking the device opens the inspector.
  final bool showInspectorOnShake;

  /// Whether to display a draggable floating bubble that opens the inspector.
  final bool showFloatingBubble;

  /// Theme mode for the inspector UI.
  final ThemeMode themeMode;

  /// Force a text direction in the inspector. If null, uses the host app's.
  final TextDirection? directionality;

  /// Acceleration threshold (m/s^2) to trigger a shake event. Higher = harder
  /// shake required.
  final double shakeThreshold;

  SamseerConfiguration copyWith({
    int? maxCallsCount,
    bool? showInspectorOnShake,
    bool? showFloatingBubble,
    ThemeMode? themeMode,
    TextDirection? directionality,
    double? shakeThreshold,
  }) {
    return SamseerConfiguration(
      maxCallsCount: maxCallsCount ?? this.maxCallsCount,
      showInspectorOnShake: showInspectorOnShake ?? this.showInspectorOnShake,
      showFloatingBubble: showFloatingBubble ?? this.showFloatingBubble,
      themeMode: themeMode ?? this.themeMode,
      directionality: directionality ?? this.directionality,
      shakeThreshold: shakeThreshold ?? this.shakeThreshold,
    );
  }
}
