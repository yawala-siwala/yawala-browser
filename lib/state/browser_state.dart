import 'package:flutter/foundation.dart';

import '../domain/model.dart';
import '../domain/service.dart';
import '../native/platform_bindings.dart';
import '../native/web_engine.dart';

/// Reactive state machine for Yawala Browser.
///
/// Owns the open [WebTab] set, active-tab selection, the address bar and
/// URL normalisation, per-tab back history, engine attachment, custom-tab
/// hand-off and privacy clearing. Every native call flows through
/// [BrowserNativeBinding] (backed by core's `NativeChannelGateway`), so
/// unsupported platforms degrade to safe fallbacks instead of throwing.
class BrowserState extends ChangeNotifier {
  BrowserState({
    required BrowserNativeBinding native,
    required BrowserService service,
    WebEngineFactory? engineFactory,
  })  : _native = native,
        _service = service,
        _engineFactory = engineFactory;

  final BrowserNativeBinding _native;
  final BrowserService _service;

  /// Optional real web-rendering factory (webview_flutter). When present,
  /// [attachEngineToActiveTab] attaches a live engine per tab and page
  /// events stream back through [pageDidStart]/[pageDidFinish].
  final WebEngineFactory? _engineFactory;

  List<WebTab> _tabs = const <WebTab>[];
  String? _activeTabId;
  String _filter = '';
  String _addressText = '';
  final Map<String, List<String>> _history = <String, List<String>>{};
  final Map<String, WebViewHandle> _engineHandles = <String, WebViewHandle>{};
  final Map<String, WebEngine> _engines = <String, WebEngine>{};
  bool _lastCustomTabOpened = false;
  DateTime? _lastClearedAt;

  /// Every open tab, in open order.
  List<WebTab> get tabs => List.unmodifiable(_tabs);

  /// Tabs matching the filter (for the tab strip / switcher).
  List<WebTab> get visibleTabs => _filter.isEmpty
      ? _tabs
      : _tabs.where((tab) => tab.matches(_filter)).toList(growable: false);

  WebTab? get activeTab => _activeTabId == null ? null : _byId(_activeTabId!);

  String get filter => _filter;
  String get addressText => _addressText;
  bool get lastCustomTabOpened => _lastCustomTabOpened;

  /// When cookies/cache were last cleared, for status feedback.
  DateTime? get lastClearedAt => _lastClearedAt;

  /// Whether the active tab can navigate back.
  bool get canGoBack {
    final tab = activeTab;
    if (tab == null) {
      return false;
    }
    return (_history[tab.id] ?? const <String>[]).isNotEmpty;
  }

  /// Number of back entries recorded for [tabId].
  int historyDepthFor(String tabId) =>
      (_history[tabId] ?? const <String>[]).length;

  /// The attached native engine handle for [tabId], if any.
  WebViewHandle? engineHandleFor(String tabId) => _engineHandles[tabId];

  /// The live web-rendering engine for [tabId], when the platform supports
  /// real page rendering and the engine was attached.
  WebEngine? engineFor(String tabId) => _engines[tabId];

  /// Boots the session with a start tab when the workspace is empty.
  Future<void> load() async {
    if (_tabs.isEmpty) {
      await openTab('https://flutter.dev');
    }
  }

  /// Opens a new tab for [input] (URL or search phrase) and activates it.
  Future<WebTab> openTab(String input) async {
    final tab = _service.createTab(input);
    _tabs = [..._tabs, tab];
    _activeTabId = tab.id;
    _addressText = tab.url;
    notifyListeners();
    return tab;
  }

  /// Makes [tabId] the active tab and mirrors its URL into the address bar.
  void activate(String tabId) {
    final tab = _byId(tabId);
    if (tab == null) {
      return;
    }
    _activeTabId = tabId;
    _addressText = tab.url;
    notifyListeners();
  }

  /// Closes a tab; when the active tab closes, activation falls to the
  /// last remaining tab. Engine handles, live engines and history are
  /// dropped too.
  void close(String tabId) {
    _tabs = _tabs.where((tab) => tab.id != tabId).toList(growable: false);
    _history.remove(tabId);
    _engineHandles.remove(tabId);
    _engines.remove(tabId);
    if (_activeTabId == tabId) {
      _activeTabId = _tabs.isEmpty ? null : _tabs.last.id;
      final tab = activeTab;
      _addressText = tab?.url ?? '';
    }
    notifyListeners();
  }

  /// Updates the address bar text as the user types.
  void setAddressText(String value) {
    _addressText = value;
    notifyListeners();
  }

  /// Updates the tab-strip filter.
  void setFilter(String value) {
    _filter = value.trim().toLowerCase();
    notifyListeners();
  }

  /// Normalises the address bar through [BrowserService.resolveInput],
  /// pushes the current URL onto the back history and navigates the active
  /// tab. Title, address bar and loading status all stay in sync. No-op
  /// without an active tab.
  Future<void> submitAddress() async {
    final tab = activeTab;
    if (tab == null) {
      return;
    }
    final resolved = _service.resolveInput(_addressText);
    _addressText = resolved;
    _pushHistory(tab.id, tab.url);
    _updateTab(
      tab.id,
      (current) => current.copyWith(
        url: resolved,
        title: _service.titleFor(resolved),
        isLoading: true,
      ),
    );
    notifyListeners();
    await _native.navigate(tabId: tab.id, url: resolved);
    // Drive the live engine (when attached) to the resolved URL; its page
    // callbacks stream the loading state back through [pageDidStart].
    unawaited(_engines[tab.id]?.load(resolved));
    _updateTab(tab.id, (current) => current.copyWith(isLoading: false));
    notifyListeners();
  }

  /// Pops the back history of the active tab and navigates to the previous
  /// URL, mirroring the same title/address/loading sync as
  /// [submitAddress]. No-op on an empty history.
  Future<void> goBack() async {
    final tab = activeTab;
    if (tab == null) {
      return;
    }
    final stack = _history[tab.id];
    if (stack == null || stack.isEmpty) {
      return;
    }
    final previous = stack.removeLast();
    _addressText = previous;
    _updateTab(
      tab.id,
      (current) => current.copyWith(
        url: previous,
        title: _service.titleFor(previous),
        isLoading: true,
      ),
    );
    notifyListeners();
    await _native.navigate(tabId: tab.id, url: previous);
    unawaited(_engines[tab.id]?.load(previous));
    _updateTab(tab.id, (current) => current.copyWith(isLoading: false));
    notifyListeners();
  }

  /// Attaches a native web view engine to the active tab (null on
  /// unsupported platforms - the handle simply stays absent) and, when a
  /// real [WebEngineFactory] is available, a live rendering engine that
  /// immediately loads the tab's URL.
  Future<void> attachEngineToActiveTab() async {
    final tab = activeTab;
    if (tab == null) {
      return;
    }
    final handle = await _native.createWebViewController(
      tabId: tab.id,
      initialUrl: tab.url,
    );
    if (handle != null) {
      _engineHandles[tab.id] = handle;
    }
    await attachRealEngine(tab.id, tab.url);
    notifyListeners();
  }

  /// Creates and stores the live rendering engine for [tabId] through the
  /// injected factory (no-op when absent or already attached).
  Future<void> attachRealEngine(String tabId, String initialUrl) async {
    final factory = _engineFactory;
    if (factory == null || _engines.containsKey(tabId)) {
      return;
    }
    final engine = await factory.create(
      tabId: tabId,
      initialUrl: initialUrl,
      onPageStarted: (url) => pageDidStart(tabId, url),
      onPageFinished: (url, title) => pageDidFinish(tabId, url, title),
    );
    if (engine != null) {
      _engines[tabId] = engine;
    }
  }

  /// Called by the live engine when a page starts loading: syncs the tab's
  /// URL and loading state, and mirrors the URL into the address bar when
  /// the tab is active.
  void pageDidStart(String tabId, String url) {
    _updateTab(
      tabId,
      (current) => current.copyWith(url: url, isLoading: true),
    );
    if (_activeTabId == tabId && url.isNotEmpty) {
      _addressText = url;
    }
    notifyListeners();
  }

  /// Called by the live engine when a page finishes: records the real
  /// document title (falling back to the URL's host) and clears loading.
  void pageDidFinish(String tabId, String url, String? title) {
    _updateTab(
      tabId,
      (current) => current.copyWith(
        url: url,
        title: (title == null || title.isEmpty)
            ? _service.titleFor(url)
            : title,
        isLoading: false,
      ),
    );
    if (_activeTabId == tabId && url.isNotEmpty) {
      _addressText = url;
    }
    notifyListeners();
  }

  /// Hands [url] (default: the active tab's URL) to a Custom Tab /
  /// SFSafariView / system browser and records the outcome.
  Future<bool> openInCustomTab([String? url]) async {
    final target = url ?? activeTab?.url ?? _service.resolveInput(_addressText);
    _lastCustomTabOpened = await _native.openCustomTab(target);
    notifyListeners();
    return _lastCustomTabOpened;
  }

  /// Clears cookies and cached web data; timestamps the event for the UI.
  Future<void> clearCookiesAndCache() async {
    await _native.clearCookiesAndCache();
    _lastClearedAt = DateTime.now();
    notifyListeners();
  }

  WebTab? _byId(String tabId) {
    for (final tab in _tabs) {
      if (tab.id == tabId) {
        return tab;
      }
    }
    return null;
  }

  void _pushHistory(String tabId, String url) {
    final stack = _history.putIfAbsent(tabId, () => <String>[]);
    stack.add(url);
  }

  void _updateTab(String tabId, WebTab Function(WebTab current) transform) {
    _tabs = [
      for (final tab in _tabs)
        if (tab.id == tabId) transform(tab) else tab,
    ];
  }
}
