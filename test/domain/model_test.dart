import 'package:flutter_test/flutter_test.dart';

import 'package:yawala_browser/domain/model.dart';

void main() {
  group('WebTab', () {
    test('sample data is not empty', () {
      expect(WebTab.seedLibrary, isNotEmpty);
    });

    test('matches humanised labels', () {
      for (final item in WebTab.seedLibrary) {
        expect(item.matches(item.displayName.toLowerCase()), isTrue);
      }
    });
  });
}