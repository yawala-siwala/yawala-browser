import 'package:flutter_test/flutter_test.dart';

import 'package:yawala_browser/domain/service.dart';
import 'package:yawala_browser/native/platform_bindings.dart';
import 'package:yawala_browser/state/browser_state.dart';

/// Scriptable native binding for state tests.
class FakeBrowserBinding implements BrowserNativeBinding {
  bool customTabResult = true;
  WebViewHandle? nextHandle;
  List<String> navigations = <String>[];
  List<String> customTabs = <String>[];
  int clearCount = 0;

  @override
  Future<bool> openCustomTab(String url) async {
    customTabs.add(url);
    return customTabResult;
  }

  @override
  Future<WebViewHandle?> createWebViewController({
    required String tabId,
    required String initialUrl,
  }) async =>
      nextHandle;

  @override
  Future<void> navigate({required String tabId, required String url}) async {
    navigations.add(url);
  }

  @override
  Future<void> clearCookiesAndCache() async {
    clearCount += 1;
  }
}

BrowserState buildState({FakeBrowserBinding? native}) {
  return BrowserState(
    native: native ?? FakeBrowserBinding(),
    service: BrowserService(),
  );
}

void main() {
  group('BrowserState tab lifecycle', () {
    test('load opens a start tab and activates it', () async {
      final state = buildState();
      await state.load();

      expect(state.tabs, hasLength(1));
      expect(state.activeTab?.url, 'https://flutter.dev');
      expect(state.addressText, 'https://flutter.dev');
    });

    test('openTab appends, activates and mirrors the URL', () async {
      final state = buildState();
      await state.load();

      final tab = await state.openTab('docs.opencode.dev');

      expect(state.tabs, hasLength(2));
      expect(state.activeTab?.id, tab.id);
      expect(tab.url, 'https://docs.opencode.dev');
      expect(state.addressText, 'https://docs.opencode.dev');
    });

    test('openTab turns search phrases into a web search', () async {
      final state = buildState();

      final tab = await state.openTab('flutter widgets');

      expect(tab.url, startsWith('https://duckduckgo.com/?q='));
      expect(tab.url, contains('flutter'));
    });

    test('openTab keeps about:blank intact', () async {
      final state = buildState();

      final tab = await state.openTab('about:blank');

      expect(tab.url, 'about:blank');
    });

    test('activate switches the active tab and address bar', () async {
      final state = buildState();
      await state.load();
      final first = state.tabs.first;
      await state.openTab('https://dart.dev');

      state.activate(first.id);

      expect(state.activeTab?.id, first.id);
      expect(state.addressText, first.url);
    });

    test('activate ignores unknown tab ids', () async {
      final state = buildState();
      await state.load();
      final active = state.activeTab;

      state.activate('tab-missing');

      expect(state.activeTab, active);
    });

    test('close falls back to the last remaining tab', () async {
      final state = buildState();
      await state.load();
      await state.openTab('https://dart.dev');
      final closing = state.activeTab!;

      state.close(closing.id);

      expect(state.tabs, hasLength(1));
      expect(state.activeTab?.url, 'https://flutter.dev');
      expect(state.addressText, 'https://flutter.dev');
    });

    test('closing every tab empties the workspace', () async {
      final state = buildState();
      await state.load();

      state.close(state.activeTab!.id);

      expect(state.tabs, isEmpty);
      expect(state.activeTab, isNull);
      expect(state.addressText, isEmpty);
    });

    test('close forgets the tab history and engine handle', () async {
      final native = FakeBrowserBinding()
        ..nextHandle = const WebViewHandle(tabId: 'tab-1', engineId: 'engine-1');
      final state = buildState(native: native);
      await state.load();
      final tab = state.activeTab!;
      state.setAddressText('https://dart.dev');
      await state.submitAddress();
      await state.attachEngineToActiveTab();
      expect(state.engineHandleFor(tab.id), isNotNull);

      state.close(tab.id);

      expect(state.historyDepthFor(tab.id), 0);
      expect(state.engineHandleFor(tab.id), isNull);
    });
  });

  group('BrowserState URL normalisation and navigation', () {
    test('submitAddress normalises bare hosts and records history', () async {
      final native = FakeBrowserBinding();
      final state = buildState(native: native);
      await state.load();

      state.setAddressText('example.com');
      await state.submitAddress();

      expect(state.activeTab?.url, 'https://example.com');
      expect(state.addressText, 'https://example.com');
      expect(state.historyDepthFor(state.activeTab!.id), 1);
      expect(state.canGoBack, isTrue);
      expect(native.navigations, ['https://example.com']);
      expect(state.activeTab?.isLoading, isFalse);
    });

    test('goBack restores the previous URL and address text', () async {
      final native = FakeBrowserBinding();
      final state = buildState(native: native);
      await state.load();
      final original = state.activeTab!.url;

      state.setAddressText('https://dart.dev');
      await state.submitAddress();
      await state.goBack();

      expect(state.activeTab?.url, original);
      expect(state.addressText, original);
      expect(state.canGoBack, isFalse);
      expect(native.navigations, ['https://dart.dev', original]);
    });

    test('goBack is a safe no-op without history', () async {
      final native = FakeBrowserBinding();
      final state = buildState(native: native);
      await state.load();

      await state.goBack();

      expect(state.activeTab?.url, 'https://flutter.dev');
      expect(native.navigations, isEmpty);
    });

    test('submitAddress without an active tab is a safe no-op', () async {
      final native = FakeBrowserBinding();
      final state = buildState(native: native);

      state.setAddressText('example.com');
      await state.submitAddress();

      expect(state.tabs, isEmpty);
      expect(native.navigations, isEmpty);
    });

    test('empty address resolves to about:blank', () async {
      final state = buildState();
      await state.load();

      state.setAddressText('   ');
      await state.submitAddress();

      expect(state.activeTab?.url, 'about:blank');
    });
  });

  group('BrowserState filtering', () {
    test('setFilter matches titles and hosts case-insensitively', () async {
      final state = buildState();
      await state.load();
      await state.openTab('https://docs.opencode.dev');

      state.setFilter('FLUTTER');
      expect(state.visibleTabs, hasLength(1));
      expect(state.visibleTabs.single.host, 'flutter.dev');

      state.setFilter('');
      expect(state.visibleTabs, hasLength(2));
    });
  });

  group('BrowserState native bridge', () {
    test('attachEngineToActiveTab stores the native handle', () async {
      final native = FakeBrowserBinding()
        ..nextHandle = const WebViewHandle(tabId: 'tab-1', engineId: 'engine-1');
      final state = buildState(native: native);
      await state.load();

      await state.attachEngineToActiveTab();

      expect(state.engineHandleFor('tab-1')?.engineId, 'engine-1');
    });

    test('openInCustomTab reports success and records the URL', () async {
      final native = FakeBrowserBinding();
      final state = buildState(native: native);
      await state.load();

      final opened = await state.openInCustomTab();

      expect(opened, isTrue);
      expect(state.lastCustomTabOpened, isTrue);
      expect(native.customTabs, ['https://flutter.dev']);
    });

    test('openInCustomTab can target an explicit URL', () async {
      final native = FakeBrowserBinding();
      final state = buildState(native: native);
      await state.load();

      await state.openInCustomTab('example.com');

      // The caller-supplied value is handed over as-is.
      expect(native.customTabs, ['example.com']);
    });

    test('clearCookiesAndCache timestamps the event', () async {
      final native = FakeBrowserBinding();
      final state = buildState(native: native);
      await state.load();

      expect(state.lastClearedAt, isNull);
      await state.clearCookiesAndCache();

      expect(native.clearCount, 1);
      expect(state.lastClearedAt, isNotNull);
    });
  });

  group('BrowserState safe fallbacks', () {
    test('the fallback binding keeps tab management functional', () async {
      final state = BrowserState(
        native: const FallbackBrowserBinding(),
        service: BrowserService(),
      );
      await state.load();
      await state.openTab('flutter.dev');

      state.setAddressText('dart.dev');
      await state.submitAddress();
      expect(state.activeTab?.url, 'https://dart.dev');
      expect(state.canGoBack, isTrue);

      await state.goBack();
      expect(state.activeTab?.url, 'https://flutter.dev');

      await state.attachEngineToActiveTab();
      expect(state.engineHandleFor(state.activeTab!.id), isNull);

      expect(await state.openInCustomTab(), isFalse);
      expect(state.lastCustomTabOpened, isFalse);

      await state.clearCookiesAndCache();
      expect(state.lastClearedAt, isNotNull);
    });
  });
}
