import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:yawala_browser/native/platform_bindings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final binding = MethodChannelBrowserBinding();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(browserChannel, null);
  });

  group('MethodChannelBrowserBinding with a live native handler', () {
    test('openCustomTab reports a successful hand-off', () async {
      messenger.setMockMethodCallHandler(browserChannel, (call) async {
        expect(call.method, 'openCustomTab');
        expect((call.arguments as Map<Object?, Object?>)['url'],
            'https://flutter.dev');
        return true;
      });

      expect(await binding.openCustomTab('https://flutter.dev'), isTrue);
    });

    test('createWebViewController maps the engine handle', () async {
      messenger.setMockMethodCallHandler(browserChannel, (call) async {
        return {'tabId': 'tab-1', 'engineId': 'wk-42'};
      });

      final handle = await binding.createWebViewController(
        tabId: 'tab-1',
        initialUrl: 'https://flutter.dev',
      );

      expect(handle?.tabId, 'tab-1');
      expect(handle?.engineId, 'wk-42');
    });

    test('navigate and clearCookiesAndCache forward their arguments',
        () async {
      final methods = <String>[];
      messenger.setMockMethodCallHandler(browserChannel, (call) async {
        methods.add(call.method);
        return null;
      });

      await binding.navigate(tabId: 'tab-2', url: 'https://example.com');
      await binding.clearCookiesAndCache();

      expect(methods, ['navigate', 'clearCookiesAndCache']);
    });
  });

  group('channel invocation safety (no native handler registered)', () {
    test('openCustomTab degrades to false', () async {
      expect(await binding.openCustomTab('https://flutter.dev'), isFalse);
    });

    test('web view attach degrades to null', () async {
      expect(
        await binding.createWebViewController(
          tabId: 'tab-1',
          initialUrl: 'https://flutter.dev',
        ),
        isNull,
      );
    });

    test('navigation and cache calls complete without throwing', () async {
      await binding.navigate(tabId: 'tab-1', url: 'https://example.com');
      await binding.clearCookiesAndCache();
    });
  });

  group('FallbackBrowserBinding', () {
    const fallback = FallbackBrowserBinding();

    test('mirrors the safe fallbacks', () async {
      expect(await fallback.openCustomTab('https://x'), isFalse);
      expect(
        await fallback.createWebViewController(
          tabId: 't',
          initialUrl: 'https://x',
        ),
        isNull,
      );
      await fallback.navigate(tabId: 't', url: 'https://x');
      await fallback.clearCookiesAndCache();
    });
  });
}
