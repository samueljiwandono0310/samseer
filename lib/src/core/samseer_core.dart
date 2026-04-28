import 'package:flutter/material.dart';

import '../feature/shake_detector.dart';
import '../model/http_call.dart';
import '../model/http_error.dart';
import '../model/http_response.dart';
import '../ui/screen/call_list_screen.dart';
import 'samseer_configuration.dart';
import 'samseer_storage.dart';

/// Internal controller. Public users interact with [Samseer], not this.
class SamseerCore {
  SamseerCore({SamseerConfiguration? configuration})
      : configuration = configuration ?? const SamseerConfiguration() {
    storage = SamseerStorage(maxCallsCount: this.configuration.maxCallsCount);
    if (this.configuration.showInspectorOnShake) {
      _shakeDetector = ShakeDetector(
        threshold: this.configuration.shakeThreshold,
        onShake: openInspector,
      );
      // Defer start until the Flutter binding is initialized. Allows
      // callers to construct Samseer before runApp() / ensureInitialized().
      Future<void>.microtask(() => _shakeDetector?.start());
    }
  }

  final SamseerConfiguration configuration;
  late final SamseerStorage storage;
  ShakeDetector? _shakeDetector;

  final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'samseer.navigatorKey');

  int _idSeed = 0;
  int nextId() => ++_idSeed;

  void addCall(SamseerHttpCall call) => storage.addCall(call);

  void addResponse(int id, SamseerHttpResponse response) =>
      storage.updateResponse(id, response);

  void addError(int id, SamseerHttpError error) =>
      storage.updateError(id, error);

  /// Open the inspector. Requires that [navigatorKey] is attached to the
  /// host [MaterialApp.navigatorKey].
  Future<void> openInspector() async {
    final state = navigatorKey.currentState;
    if (state == null) return;
    final context = state.context;
    final isAlreadyOpen = ModalRoute.of(context)?.settings.name == kCallListRoute;
    if (isAlreadyOpen) return;
    await state.push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: kCallListRoute),
        builder: (_) => CallListScreen(core: this),
      ),
    );
  }

  /// Open the inspector against a known [BuildContext].
  Future<void> openInspectorFromContext(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: kCallListRoute),
        builder: (_) => CallListScreen(core: this),
      ),
    );
  }

  void dispose() {
    _shakeDetector?.stop();
    storage.dispose();
  }
}

const String kCallListRoute = 'samseer.callList';
