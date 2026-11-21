import 'package:flutter_test/flutter_test.dart';

import 'package:material_ui/material_ui.dart';

import 'package:yawala_browser/domain/service.dart';
import 'package:yawala_browser/native/platform_bindings.dart';
import 'package:yawala_browser/state/browser_state.dart';
import 'package:yawala_browser/ui/screens/home_screen.dart';
import 'package:yawala_browser/ui/widgets/address_bar.dart';
import 'package:yawala_browser/ui/widgets/browser_toolbar.dart';
import 'package:yawala_browser/ui/widgets/page_status_panel.dart';
import 'package:yawala_browser/ui/widgets/tab_strip.dart';

/// Scriptable native binding for widget tests.
class FakeBrowserBinding implements BrowserNativeBinding {
  WebViewHandle? nextHandle;
  List<String> navigations = <String>[];
  int clearCount = 0;

  @override
  Future<bool> openCustomTab(String url) async => true;

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

BrowserState buildState(FakeBrowserBinding native) {
  return BrowserState(
    native: native,
    service: BrowserService(),
  );
}

void main() {
  testWidgets('narrow layout keeps the workspace functional end to end',
      (tester) async {
    tester.view.physicalSize = const Size(600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final native = FakeBrowserBinding()
      ..nextHandle = const WebViewHandle(tabId: 'tab-1', engineId: 'engine-1');
    final state = buildState(native);
    await state.load();

    await tester.pumpWidget(MaterialApp(home: BrowserHomeScreen(state: state)));
    await tester.pumpAndSettle();

    // Narrow stack: address bar, tab strip, status panel - no side toolbar.
    expect(find.byType(AddressBar), findsOneWidget);
    expect(find.byType(TabStrip), findsOneWidget);
    expect(find.byType(PageStatusPanel), findsOneWidget);
    expect(find.byType(BrowserToolbar), findsNothing);
    // Tab chips show the host-derived title, not the raw URL.
    expect(find.text('flutter.dev'), findsWidgets);

    // Navigate through the omnibox: URL + title + history stay in sync.
    await tester.enterText(find.byType(TextField), 'example.com');
    await tester.tap(find.byTooltip('Go'));
    await tester.pumpAndSettle();
    expect(state.activeTab?.url, 'https://example.com');
    expect(state.activeTab?.title, 'example.com');
    expect(find.text('https://example.com'), findsWidgets);
    expect(native.navigations, ['https://example.com']);

    // Back navigation restores the previous page everywhere.
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(state.activeTab?.url, 'https://flutter.dev');
    expect(find.text('https://flutter.dev'), findsWidgets);

    // New tab opens about:blank and becomes active.
    await tester.tap(find.text('New tab'));
    await tester.pumpAndSettle();
    expect(state.tabs, hasLength(2));
    expect(state.activeTab?.url, 'about:blank');

    // Switch back to the first tab via its chip.
    final firstChip = find.ancestor(
      of: find.text('flutter.dev'),
      matching: find.byType(InputChip),
    );
    await tester.tap(firstChip.first);
    await tester.pumpAndSettle();
    expect(state.activeTab?.url, 'https://flutter.dev');

    // Attach the native engine for the active tab.
    await tester.tap(find.text('Attach engine'));
    await tester.pumpAndSettle();
    expect(find.textContaining('attached: engine-1'), findsOneWidget);

    // Close the active tab via its chip's delete affordance.
    await tester.tap(
      find.descendant(of: firstChip.first, matching: find.byIcon(Icons.cancel)),
    );
    await tester.pumpAndSettle();
    expect(state.tabs, hasLength(1));
    expect(state.activeTab?.url, 'about:blank');

    // Clear cookies/cache behind the confirmation dialog.
    await tester.tap(find.byTooltip('Clear cookies & cache'));
    await tester.pumpAndSettle();
    expect(find.text('Clear cookies & cache?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Clear'));
    await tester.pump();
    expect(find.text('Cookies and cache cleared.'), findsOneWidget);
    expect(state.lastClearedAt, isNotNull);
    expect(native.clearCount, 1);
  });

  testWidgets('wide layout renders the two-pane workspace', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = buildState(FakeBrowserBinding());
    await state.load();

    await tester.pumpWidget(MaterialApp(home: BrowserHomeScreen(state: state)));
    await tester.pumpAndSettle();

    // Wide layout adds the side tab-list toolbar next to the status pane.
    expect(find.byType(BrowserToolbar), findsOneWidget);
    expect(find.byType(TabStrip), findsOneWidget);
    expect(find.byType(PageStatusPanel), findsOneWidget);
    expect(find.byType(AddressBar), findsOneWidget);

    // The side toolbar's search filters tab chips live.
    final toolbarField = find.descendant(
      of: find.byType(BrowserToolbar),
      matching: find.byType(TextField),
    );
    await tester.enterText(toolbarField, 'flutter');
    await tester.pump();
    expect(state.visibleTabs, hasLength(1));
  });
}
