import 'package:flutter/widgets.dart';

import 'package:webview_flutter/webview_flutter.dart';

/// A live web-rendering engine attached to one browser tab.
///
/// The abstraction keeps [BrowserState] and every test free of the
/// `webview_flutter` plugin: the real engine is created through
/// [WebViewEngineFactory], while fakes can implement the same interface.
abstract class WebEngine {
  /// The platform view that renders the page.
  Widget buildView();

  /// Navigates to [url]. `about:blank` loads an empty document.
  Future<void> load(String url);

  Future<bool> canGoBack();

  Future<bool> canGoForward();

  Future<void> back();

  Future<void> forward();

  Future<void> reload();
}

/// Creates engines for tabs. Callbacks keep [BrowserState] as the single
/// source of truth for URL, title and loading state.
abstract class WebEngineFactory {
  Future<WebEngine?> create({
    required String tabId,
    required String initialUrl,
    required void Function(String url) onPageStarted,
    required void Function(String url, String? title) onPageFinished,
  });
}

/// Real engine over the `webview_flutter` plugin.
class WebViewEngineFactory implements WebEngineFactory {
  const WebViewEngineFactory();

  @override
  Future<WebEngine?> create({
    required String tabId,
    required String initialUrl,
    required void Function(String url) onPageStarted,
    required void Function(String url, String? title) onPageFinished,
  }) async {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: onPageStarted,
          onPageFinished: (url) {
            // The document title only exists once the page finished parsing.
            controller.getTitle().then((title) => onPageFinished(url, title));
          },
        ),
      );
    await loadInto(controller, initialUrl);
    return WebViewEngine(controller);
  }

  /// Loads [url] handling the `about:blank` scheme, which [loadRequest]
  /// rejects because it is not http(s).
  static Future<void> loadInto(WebViewController controller, String url) {
    if (url == 'about:blank' || Uri.tryParse(url)?.scheme.isEmpty == true) {
      return controller.loadHtmlString(
        '<!doctype html><html><body style="background:#111;color:#eee;'
        'font-family:sans-serif;display:grid;place-items:center;height:100vh;'
        'margin:0"><p>Yawala Browser</p></body></html>',
      );
    }
    final uri = Uri.tryParse(url);
    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
      return Future.value();
    }
    return controller.loadRequest(uri);
  }
}

class WebViewEngine implements WebEngine {
  WebViewEngine(this.controller);

  final WebViewController controller;

  @override
  Widget buildView() => WebViewWidget(controller: controller);

  @override
  Future<void> load(String url) => WebViewEngineFactory.loadInto(controller, url);

  @override
  Future<bool> canGoBack() => controller.canGoBack();

  @override
  Future<bool> canGoForward() => controller.canGoForward();

  @override
  Future<void> back() => controller.back();

  @override
  Future<void> forward() => controller.forward();

  @override
  Future<void> reload() => controller.reload();
}
