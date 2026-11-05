import 'package:flutter/foundation.dart';

import '../domain/model.dart';
import '../domain/service.dart';

/// Owns the observable state of Yawala Browser: filtered tabs, loading
/// flag and app-scoped runtime flags. Widgets rebuild via notifyListeners.
class BrowserState extends ChangeNotifier {
  BrowserState({required BrowserService service}) : _service = service;

  final BrowserService _service;
  String _filter = '';
  bool _loading = false;
  List<WebTab> _items = const [];

  WebTab? _activeTab;

  WebTab? get activeTab => _activeTab;


  Iterable<WebTab> get items => _filter.isEmpty
      ? _items
      : _items.where((item) => item.matches(_filter.toLowerCase()));

  bool get isLoading => _loading;

  void setFilter(String value) {
    _filter = value.trim().toLowerCase();
    notifyListeners();
  }

  /// Creates a new tab pointing at [input] (a URL or a search phrase).
  Future<void> openNewTab(String input) async {
    final tab = _service.createTab(input);
    _items = [..._items, tab];
    _activeTab = tab;
    notifyListeners();
  }

  void activate(WebTab tab) {
    _activeTab = tab;
    notifyListeners();
  }

  void close(WebTab tab) {
    _items = _items.where((t) => t.id != tab.id).toList(growable: false);
    if (_activeTab?.id == tab.id) {
      _activeTab = _items.isEmpty ? null : _items.last;
    }
    notifyListeners();
  }

  Future<void> reload() async {
    _loading = true;
    notifyListeners();
    try {
      _items = await _service.list();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}