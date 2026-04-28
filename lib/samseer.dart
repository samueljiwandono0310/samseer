/// Samseer — beautiful HTTP inspector for Flutter.
///
/// Catches HTTP requests/responses from Dio, the `http` package, and
/// `dart:io` HttpClient and presents them in a Material 3 inspector UI.
library;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'src/core/samseer_configuration.dart';
import 'src/core/samseer_core.dart';
import 'src/feature/floating_bubble.dart';
import 'src/interceptor/dio_interceptor.dart';
import 'src/interceptor/http_client.dart';
import 'src/interceptor/http_overrides.dart';
import 'src/model/http_call.dart';

export 'src/core/samseer_configuration.dart';
export 'src/feature/floating_bubble.dart' show SamseerOverlay;
export 'src/interceptor/dio_interceptor.dart' show SamseerDioInterceptor;
export 'src/interceptor/http_client.dart' show SamseerHttpClient;
export 'src/interceptor/http_overrides.dart' show SamseerHttpOverrides;
export 'src/model/http_call.dart' show SamseerHttpCall, SamseerCallState;
export 'src/model/http_error.dart' show SamseerHttpError;
export 'src/model/http_request.dart' show SamseerHttpRequest;
export 'src/model/http_response.dart' show SamseerHttpResponse;

/// Public entry point of the Samseer HTTP inspector.
///
/// ```dart
/// final samseer = Samseer();
///
/// MaterialApp(
///   navigatorKey: samseer.navigatorKey,
///   home: HomeScreen(),
/// );
///
/// // Dio
/// dio.interceptors.add(samseer.dioInterceptor);
///
/// // http package
/// final client = samseer.httpClient();
///
/// // dart:io HttpClient (global)
/// HttpOverrides.global = samseer.httpOverrides;
/// ```
class Samseer {
  Samseer({SamseerConfiguration configuration = const SamseerConfiguration()})
      : _core = SamseerCore(configuration: configuration);

  final SamseerCore _core;

  /// Configuration this instance was constructed with.
  SamseerConfiguration get configuration => _core.configuration;

  /// Attach this to your root [MaterialApp.navigatorKey] so Samseer can open
  /// the inspector from shake/floating-bubble triggers.
  GlobalKey<NavigatorState> get navigatorKey => _core.navigatorKey;

  /// Snapshot of all currently recorded calls (newest first).
  List<SamseerHttpCall> get calls => _core.storage.calls;

  /// Reactive stream of recorded calls.
  Stream<List<SamseerHttpCall>> get callsStream => _core.storage.stream;

  /// Dio interceptor — add to `dio.interceptors`.
  SamseerDioInterceptor get dioInterceptor => SamseerDioInterceptor(_core);

  /// Drop-in replacement for [http.Client] from the `http` package.
  /// Pass an [inner] client to delegate to (defaults to a new [http.Client]).
  SamseerHttpClient httpClient([http.Client? inner]) =>
      SamseerHttpClient(_core, inner);

  /// HttpOverrides for `dart:io` [HttpClient]. Install at startup:
  /// ```dart
  /// HttpOverrides.global = samseer.httpOverrides;
  /// ```
  SamseerHttpOverrides get httpOverrides => SamseerHttpOverrides(_core);

  /// Wrap your app's widget with [SamseerOverlay] to display a draggable
  /// floating bubble that opens the inspector on tap.
  Widget overlay({required Widget child}) =>
      SamseerOverlay(core: _core, child: child);

  /// Open the inspector. Requires [navigatorKey] is wired to MaterialApp.
  Future<void> showInspector() => _core.openInspector();

  /// Open the inspector against a known [BuildContext]. Useful in cases where
  /// you don't want to use the navigator key.
  Future<void> showInspectorFromContext(BuildContext context) =>
      _core.openInspectorFromContext(context);

  /// Clear all recorded calls.
  void clear() => _core.storage.clear();

  /// Free resources. Call when you no longer need this instance.
  void dispose() => _core.dispose();
}
