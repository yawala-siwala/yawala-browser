import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'domain/service.dart';
import 'native/platform_bindings.dart';
import 'native/web_engine.dart';
import 'state/browser_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final state = BrowserState(
    native: bootBrowserNative(),
    service: BrowserService(),
    engineFactory: const WebViewEngineFactory(),
  );
  unawaited(state.load());
  runApp(YawalaApp(state: state));
}
