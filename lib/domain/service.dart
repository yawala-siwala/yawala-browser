import 'model.dart';

/// Session data access for the browser: tab creation, URL resolution and
/// sample bookmark data.
///
/// TODO(mvp): replace with native web-engine bindings
/// (`platform_bindings.dart`) that embed a real renderer per platform.
class BrowserService {
  BrowserService();

  static const List<WebTab> seedLibrary = [
    WebTab(id: 'tab-1', title: 'OpenCode docs', url: 'https://docs.opencode.dev'),
    WebTab(id: 'tab-2', title: 'Flutter', url: 'https://flutter.dev'),
    WebTab(id: 'tab-3', title: 'Yawala-Siwala org', url: 'https://github.com/yawala-siwala'),
  ];

  int _counter = 0;

  /// Normalises a raw user entry into a loadable URL.
  String resolveInput(String input) {
    final value = input.trim();
    if (value.isEmpty) {
      return 'about:blank';
    }
    final isUrl = value.startsWith('http://') ||
        value.startsWith('https://') ||
        RegExp(r'^\S+\.\S{2,}').hasMatch(value);
    if (!isUrl) {
      return 'https://duckduckgo.com/?q=${Uri.encodeQueryComponent(value)}';
    }
    return value.startsWith('http') ? value : 'https://$value';
  }

  /// Creates a tab stub; the native engine joins the session on attach.
  WebTab createTab(String input) {
    _counter += 1;
    final url = resolveInput(input);
    return WebTab(id: 'tab-$_counter', title: url, url: url);
  }

  Future<List<WebTab>> list() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return List.unmodifiable(seedLibrary);
  }
}