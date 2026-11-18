import 'package:flutter/services.dart';

import 'package:yawala_core/yawala_core.dart';

/// Native contract for Yawala Browser.
///
/// Channel: `com.yawalasiwala/browser`
///
/// | Method | Purpose | Android | iOS | Desktop |
/// | --- | --- | --- | --- | --- |
/// | `openCustomTab` | Open a URL in a Chrome Custom Tab / SFSafariView / system browser | Custom Tabs | SFSafariViewController | xdg-open / NSWorkspace / ShellExecute |
/// | `createWebViewController` | Attach an embedded web view for a tab | WebView | WKWebView | WebView2 / WKWebView / WebKitGTK |
/// | `navigate` | Load a URL in an attached web view | loadUrl | load(URL) | Navigate() / load(URL) |
/// | `clearCookiesAndCache` | Cookie + cache clearance | CookieManager / Cache | HTTPCookieStorage / URLCache | WebView2 profile / WKWebsiteDataStore |
///
/// Every call goes through [NativeChannelGateway] and therefore resolves to
/// safe fallbacks instead of throwing on platforms without a handler.
const MethodChannel browserChannel =
    MethodChannel('com.yawalasiwala/browser');

/// Handle to a web view engine attached to a browser tab.
class WebViewHandle {
  const WebViewHandle({
    required this.tabId,
    required this.engineId,
  });

  factory WebViewHandle.fromMap(Map<Object?, Object?>? map) {
    return WebViewHandle(
      tabId: (map?['tabId'] as String?) ?? '',
      engineId: (map?['engineId'] as String?) ?? '',
    );
  }

  final String tabId;
  final String engineId;
}

/// Contract every platform host implements for Yawala Browser.
abstract interface class BrowserNativeBinding {
  /// Opens [url] in a Custom Tab / SFSafariView / system browser.
  /// Returns whether the hand-off succeeded.
  Future<bool> openCustomTab(String url);

  /// Attaches a native web view engine to [tabId]; returns `null` when the
  /// platform has no embedded engine available.
  Future<WebViewHandle?> createWebViewController({
    required String tabId,
    required String initialUrl,
  });

  /// Loads [url] inside the web view attached to [tabId].
  Future<void> navigate({required String tabId, required String url});

  /// Clears all cookies and cached web data.
  Future<void> clearCookiesAndCache();
}

/// Real implementation that speaks to the host platform over
/// [browserChannel], mapping failures to safe fallbacks.
class MethodChannelBrowserBinding implements BrowserNativeBinding {
  MethodChannelBrowserBinding({MethodChannel? channel})
      : _gateway = NativeChannelGateway(
          channel: channel ?? browserChannel,
          context: 'browser.native',
        );

  final NativeChannelGateway _gateway;

  @override
  Future<bool> openCustomTab(String url) async {
    final result =
        await _gateway.invoke<bool>('openCustomTab', <String, Object?>{
      'url': url,
    });
    return result.fold(
      ok: (opened) => opened ?? false,
      err: (_, __) => false,
    );
  }

  @override
  Future<WebViewHandle?> createWebViewController({
    required String tabId,
    required String initialUrl,
  }) async {
    final result = await _gateway
        .invoke<Map<Object?, Object?>>('createWebViewController',
            <String, Object?>{'tabId': tabId, 'url': initialUrl});
    return result.fold(
      ok: (data) => data == null ? null : WebViewHandle.fromMap(data),
      err: (_, __) => null,
    );
  }

  @override
  Future<void> navigate({required String tabId, required String url}) {
    return _gateway.invokeVoid('navigate', <String, Object?>{
      'tabId': tabId,
      'url': url,
    });
  }

  @override
  Future<void> clearCookiesAndCache() {
    return _gateway.invokeVoid('clearCookiesAndCache');
  }
}

/// No-op implementation for tests and platforms without any native host.
class FallbackBrowserBinding implements BrowserNativeBinding {
  const FallbackBrowserBinding();

  @override
  Future<bool> openCustomTab(String url) async => false;

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

/// Boots the platform binding for the current OS.
BrowserNativeBinding bootBrowserNative() => MethodChannelBrowserBinding();
