import 'package:flutter_test/flutter_test.dart';

import 'package:yawala_browser/domain/service.dart';
import 'package:yawala_browser/domain/model.dart';

void main() {
  group('WebTab', () {
    test('displayName prefers the title and falls back to the host', () {
      const titled = WebTab(
        id: 'tab-1',
        title: 'example.com',
        url: 'https://example.com/home',
      );
      const untitled = WebTab(id: 'tab-2', title: '', url: 'https://dart.dev');

      expect(titled.displayName, 'example.com');
      expect(untitled.displayName, 'dart.dev');
    });

    test('meta reflects the loading state', () {
      const idle = WebTab(id: 'tab-1', title: 'a', url: 'https://a.dev');
      final loading = idle.copyWith(isLoading: true);

      expect(idle.meta, 'idle');
      expect(loading.meta, 'loading...');
    });

    test('matches titles and hosts case-insensitively', () {
      const tab = WebTab(
        id: 'tab-1',
        title: 'flutter.dev',
        url: 'https://flutter.dev/docs',
      );

      expect(tab.matches('FLUTTER'), isTrue);
      expect(tab.matches('flutter.dev'), isTrue);
      // matches() searches the display title and host only - never URL
      // paths - so a path segment like 'docs' does not match.
      expect(tab.matches('docs'), isFalse);
      expect(tab.matches('dart.dev'), isFalse);
    });

    test('copyWith keeps identity while updating fields', () {
      const tab = WebTab(id: 'tab-1', title: 'a', url: 'https://a.dev');

      final updated = tab.copyWith(url: 'https://b.dev', title: 'b.dev');

      expect(updated.id, tab.id);
      expect(updated.url, 'https://b.dev');
      expect(updated.title, 'b.dev');
      expect(updated.isLoading, isFalse);
    });
  });

  group('BrowserService.resolveInput', () {
    final service = BrowserService();

    test('passes through real URLs', () {
      expect(service.resolveInput('https://flutter.dev'), 'https://flutter.dev');
    });

    test('upgrades bare hosts to https', () {
      expect(service.resolveInput('example.com'), 'https://example.com');
    });

    test('turns search phrases into a search URL', () {
      expect(
        service.resolveInput('flutter method channels'),
        startsWith('https://duckduckgo.com/?q='),
      );
    });

    test('blank input resolves to about:blank', () {
      expect(service.resolveInput('   '), 'about:blank');
    });

    test('about:blank is preserved verbatim', () {
      expect(service.resolveInput('about:blank'), 'about:blank');
    });

    test('input is trimmed before resolution', () {
      expect(service.resolveInput('  example.com  '), 'https://example.com');
    });
  });

  group('BrowserService.titleFor', () {
    final service = BrowserService();

    test('uses the host for http(s) URLs', () {
      expect(service.titleFor('https://flutter.dev/docs'), 'flutter.dev');
      expect(service.titleFor('http://example.com:8080/x'), 'example.com');
    });

    test('falls back to the URL when there is no host', () {
      expect(service.titleFor('about:blank'), 'about:blank');
      expect(service.titleFor('not a url'), 'not a url');
    });
  });

  group('BrowserService.createTab', () {
    test('assigns sequential ids and host-based titles', () {
      final service = BrowserService();

      final first = service.createTab('flutter.dev');
      final second = service.createTab('example.com');

      expect(first.id, 'tab-1');
      expect(second.id, 'tab-2');
      expect(first.url, 'https://flutter.dev');
      expect(first.title, 'flutter.dev');
      expect(second.title, 'example.com');
    });
  });
}
