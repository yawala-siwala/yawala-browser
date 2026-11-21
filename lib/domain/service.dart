import 'model.dart';

/// Session data access for the browser: tab creation, URL resolution and
/// human-friendly title derivation.
///
/// TODO(mvp): replace with native web-engine bindings
/// (`platform_bindings.dart`) that embed a real renderer per platform.
class BrowserService {
  BrowserService();

  int _counter = 0;

  /// Normalises a raw user entry into a loadable URL.
  String resolveInput(String input) {
    final value = input.trim();
    if (value.isEmpty) {
      return 'about:blank';
    }
    if (value == 'about:blank') {
      return value;
    }
    final isUrl = value.startsWith('http://') ||
        value.startsWith('https://') ||
        RegExp(r'^\S+\.\S{2,}').hasMatch(value);
    if (!isUrl) {
      return 'https://duckduckgo.com/?q=${Uri.encodeQueryComponent(value)}';
    }
    return value.startsWith('http') ? value : 'https://$value';
  }

  /// Derives the tab title for [url]: the host when the URL has one,
  /// otherwise the URL itself (covers `about:blank` and data URLs). Keeps
  /// tab chips, the address bar and the status panel showing the same label.
  String titleFor(String url) {
    final host = Uri.tryParse(url)?.host ?? '';
    return host.isEmpty ? url : host;
  }

  /// Creates a tab for [input]; the native engine joins the session on
  /// attach.
  WebTab createTab(String input) {
    _counter += 1;
    final url = resolveInput(input);
    return WebTab(id: 'tab-$_counter', title: titleFor(url), url: url);
  }
}
