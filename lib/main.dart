import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'state/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final state = BrowserState(service: BrowserService());
  unawaited(state.reload());
  runApp(YawalaApp(state: state));
}