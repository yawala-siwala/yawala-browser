import 'package:flutter_test/flutter_test.dart';

import 'package:yawala_browser/domain/service.dart';

void main() {
  group('WebTab', () {
    test('service sample session is not empty', () {
      expect(BrowserService.seedLibrary, isNotEmpty);
    });

    test('matches humanised labels', () {
      for (final tab in BrowserService.seedLibrary) {
        expect(tab.matches(tab.displayName.toLowerCase()), isTrue);
      }
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
  });
}