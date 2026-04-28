import 'package:flutter_test/flutter_test.dart';
import 'package:samseer/samseer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SamseerConfiguration', () {
    test('defaults are sane', () {
      const config = SamseerConfiguration();
      expect(config.maxCallsCount, 1000);
      expect(config.showInspectorOnShake, true);
      expect(config.showFloatingBubble, false);
    });

    test('copyWith preserves untouched fields', () {
      const config = SamseerConfiguration(maxCallsCount: 50);
      final next = config.copyWith(showFloatingBubble: true);
      expect(next.maxCallsCount, 50);
      expect(next.showFloatingBubble, true);
      expect(next.showInspectorOnShake, true);
    });
  });

  group('SamseerHttpCall.state', () {
    SamseerHttpCall buildCall({int? status, SamseerHttpError? error}) {
      return SamseerHttpCall(
        id: 1,
        method: 'GET',
        uri: 'https://example.com/api',
        endpoint: '/api',
        server: 'example.com',
        secure: true,
        client: 'Dio',
        createdAt: DateTime.now(),
        request: SamseerHttpRequest(time: DateTime.now()),
        response: status != null
            ? SamseerHttpResponse(status: status, time: DateTime.now())
            : null,
        error: error,
      );
    }

    test('classifies status codes', () {
      expect(buildCall(status: 200).state, SamseerCallState.success);
      expect(buildCall(status: 301).state, SamseerCallState.redirect);
      expect(buildCall(status: 404).state, SamseerCallState.clientError);
      expect(buildCall(status: 500).state, SamseerCallState.serverError);
    });

    test('returns loading when no response or error', () {
      expect(buildCall().state, SamseerCallState.loading);
    });

    test('returns error when error is set', () {
      expect(
        buildCall(error: const SamseerHttpError(message: 'oops')).state,
        SamseerCallState.error,
      );
    });
  });

  group('Samseer', () {
    test('records calls and exposes them via stream', () async {
      final samseer = Samseer(
        configuration: const SamseerConfiguration(showInspectorOnShake: false),
      );
      addTearDown(samseer.dispose);

      expect(samseer.calls, isEmpty);

      final emitted = <int>[];
      final sub = samseer.callsStream.listen((c) => emitted.add(c.length));
      addTearDown(sub.cancel);

      samseer.clear();
      await Future<void>.delayed(Duration.zero);
      expect(emitted, contains(0));
    });
  });
}
