import 'package:flutter/material.dart';

import 'state/app_state.dart';
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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF283593),
        ),
      ),
      home: BrowserHomeScreen(state: state),
    );
  }
}