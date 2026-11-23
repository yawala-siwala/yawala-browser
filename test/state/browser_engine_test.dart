import 'package:flutter_test/flutter_test.dart';

import 'package:material_ui/material_ui.dart';

import 'package:yawala_browser/domain/service.dart';
import 'package:yawala_browser/native/platform_bindings.dart';
import 'package:yawala_browser/native/web_engine.dart';
import 'package:yawala_browser/state/browser_state.dart';
import 'package:yawala_browser/ui/screens/home_screen.dart';
import 'package:yawala_browser/ui/widgets/page_status_panel.dart';
import 'package:yawala_browser/ui/widgets/web_page_view.dart';

/// Scriptable engine: records commands, renders a tagged placeholder view.
class FakeWebEngine implements WebEngine {
  final List<String> calls = <String>[];
  final List<String> loadedUrls = <String>[];
  bool canGoBackResult = false;
  bool canGoForwardResult = false;

  @override
  Widget buildView() => const ColoredBox(
        key: ValueKey('fake-webview-view'),
        color: Color(0xFF112233),
      );

  @override
  Future<void> load(String url) async {
    calls.add('load');
    loadedUrls.add(url);
  }

  @override
  Future<bool> canGoBack() async {
    calls.add('canGoBack');
    return canGoBackResult;
  }

  @override
  Future<bool> canGoForward() async {
    calls.add('canGoForward');
    return canGoForwardResult;
  }

  @override
  Future<void> back() async => calls.add('back');

  @override
  Future<void> forward() async => calls.add('forward');

  @override
  Future<void> reload() async => calls.add('reload');
}

class FakeWebEngineFactory implements WebEngineFactory {
  WebEngine? next = FakeWebEngine();
  final List<String> created = <String>[];

  @override
  Future<WebEngine?> create({
    required String tabId,
    required String initialUrl,
    required void Function(String url) onPageStarted,
    required void Function(String url, String? title) onPageFinished,
  }) async {
    created.add('$tabId|$initialUrl');
    final engine = next;
    if (engine is FakeWebEngine) {
      onPageStarted(initialUrl);
      onPageFinished(initialUrl, 'Initial Title');
    }
    return engine;
  }
}

/// No-op native binding (same shape as the CI-verified fake).
class NoopBrowserBinding implements BrowserNativeBinding {
  @override
  Future<bool> openCustomTab(String url) async => true;

  @override
  Future<WebViewHandle?> createWebViewController({
    required String tabId,
    required String initialUrl,
  }) async =>
      null;

  @override
  Future<void> navigate({required String tabId, required String url}) async {}

  @override
  Future<void> clearCookiesAndCache() async {}
}

BrowserState buildState({WebEngineFactory? engineFactory}) {
  return BrowserState(
    native: NoopBrowserBinding(),
    service: BrowserService(),
    engineFactory: engineFactory,
  );
}

void main() {
  group('BrowserState live web engine', () {
    test('attach creates an engine bound to the tab and initial URL',
        () async {
      final factory = FakeWebEngineFactory();
      final state = buildState(engineFactory: factory);
      await state.load();

      await state.attachEngineToActiveTab();

      final tab = state.activeTab!;
      expect(factory.created.single, '${tab.id}|https://flutter.dev');
      expect(state.engineFor(tab.id), isNotNull);
      // The factory's callbacks ran: real title recorded, loading cleared.
      expect(tab.title, 'Initial Title');
      expect(tab.isLoading, isFalse);
    });

    test('pageDidStart syncs URL, loading state and the address bar',
        () async {
      final state = buildState(engineFactory: FakeWebEngineFactory());
      await state.load();
      final tab = state.activeTab!;

      state.pageDidStart(tab.id, 'https://example.com/navigating');

      expect(state.activeTab?.url, 'https://example.com/navigating');
      expect(state.activeTab?.isLoading, isTrue);
      expect(state.addressText, 'https://example.com/navigating');
    });

    test('pageDidFinish records the real title and clears loading',
        () async {
      final state = buildState(engineFactory: FakeWebEngineFactory());
      await state.load();
      final tab = state.activeTab!;

      state.pageDidFinish(tab.id, 'https://example.com/loaded', 'Example Domain');

      expect(state.activeTab?.url, 'https://example.com/loaded');
      expect(state.activeTab?.title, 'Example Domain');
      expect(state.activeTab?.isLoading, isFalse);

      // An empty document title falls back to the URL's host.
      state.pageDidFinish(tab.id, 'https://dart.dev/', '');
      expect(state.activeTab?.title, 'dart.dev');
    });

    test('submitAddress drives the live engine to the resolved URL',
        () async {
      final factory = FakeWebEngineFactory();
      final state = buildState(engineFactory: factory);
      await state.load();
      await state.attachEngineToActiveTab();
      final engine = state.engineFor(state.activeTab!.id) as FakeWebEngine;

      state.setAddressText('example.com');
      await state.submitAddress();

      expect(engine.loadedUrls, contains('https://example.com'));
    });

    test('goBack drives the live engine to the previous URL', () async {
      final factory = FakeWebEngineFactory();
      final state = buildState(engineFactory: factory);
      await state.load();
      await state.attachEngineToActiveTab();
      final engine = state.engineFor(state.activeTab!.id) as FakeWebEngine;
      final original = state.activeTab!.url;

      state.setAddressText('https://dart.dev');
      await state.submitAddress();
      await state.goBack();

      expect(engine.loadedUrls.last, original);
    });

    test('closing a tab drops its engine', () async {
      final state = buildState(engineFactory: FakeWebEngineFactory());
      await state.load();
      final tab = state.activeTab!;
      await state.attachEngineToActiveTab();
      expect(state.engineFor(tab.id), isNotNull);

      state.close(tab.id);

      expect(state.engineFor(tab.id), isNull);
    });

    test('attaching twice does not recreate the engine', () async {
      final factory = FakeWebEngineFactory();
      final state = buildState(engineFactory: factory);
      await state.load();

      await state.attachEngineToActiveTab();
      await state.attachEngineToActiveTab();

      expect(factory.created, hasLength(1));
    });

    test('no factory means no engine - status panel path stays intact',
        () async {
      final state = buildState();
      await state.load();

      await state.attachEngineToActiveTab();

      expect(state.engineFor(state.activeTab!.id), isNull);
      // The native handle path still works without the factory.
      expect(state.engineHandleFor(state.activeTab!.id), isNull);
    });
  });

  testWidgets('workspace renders the live page view once an engine is attached',
      (tester) async {
    final state = buildState(engineFactory: FakeWebEngineFactory());
    await state.load();

    await tester.pumpWidget(MaterialApp(home: BrowserHomeScreen(state: state)));
    await tester.pumpAndSettle();

    // Before attach: the status panel placeholder.
    expect(find.byType(PageStatusPanel), findsOneWidget);
    expect(find.byType(WebPageView), findsNothing);

    await tester.tap(find.text('Attach engine'));
    await tester.pumpAndSettle();

    // After attach: the real engine view (fake-rendered placeholder) plus
    // the web controls.
    expect(find.byKey(const ValueKey('fake-webview-view')), findsOneWidget);
    expect(find.byType(WebPageView), findsOneWidget);
    expect(find.byTooltip('Web back'), findsOneWidget);
    expect(find.byTooltip('Reload page'), findsOneWidget);
  });
}
