import 'package:material_ui/material_ui.dart';

import 'package:yawala_core/yawala_core.dart';

import 'state/browser_state.dart';
import 'ui/screens/home_screen.dart';

/// Root widget for Yawala Browser.
class YawalaApp extends StatelessWidget {
  const YawalaApp({super.key, required this.state});

  final BrowserState state;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yawala Browser',
      debugShowCheckedModeBanner: false,
      theme: buildYawalaTheme(seedColor: YawalaColors.browser),
      darkTheme: buildYawalaTheme(
        brightness: Brightness.dark,
        seedColor: YawalaColors.browser,
      ),
      themeMode: ThemeMode.system,
      home: BrowserHomeScreen(state: state),
    );
  }
}
