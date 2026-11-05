import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Contract each native Yawala Browser host (Kotlin/Swift/C++/...) implements.
/// The Dart layer stays portable across Android, iOS, Linux, macOS and
/// Windows by talking to a single method channel per platform.
abstract interface class BrowserNative {
  Future<Object?> invoke(String method, [Map<String, Object?>? args]);
}

const MethodChannel browserChannel = MethodChannel('com.yawalasiwala/browser');

/// Default implementation forwarding calls over the method channel.
class MethodChannelBrowserNative implements BrowserNative {
  MethodChannelBrowserNative();

  @override
  Future<Object?> invoke(String method, [Map<String, Object?>? args]) =>
      browserChannel.invokeMethod<Object?>(method, args);
}

/// Boots the platform bindings for this OS.
BrowserNative bootBrowserNative() => MethodChannelBrowserNative();

/// Human-readable platform name for logs and feature gating.
String get platformName {
  if (kIsWeb) return 'web';
  if (Platform.isAndroid) return 'android';
  if (Platform.isIOS) return 'ios';
  if (Platform.isMacOS) return 'macos';
  if (Platform.isWindows) return 'windows';
  if (Platform.isLinux) return 'linux';
  return 'unknown';
}

/// Desktop targets share tighter bindings (window controls, FS roots, ...).
bool get isDesktop =>
    Platform.isMacOS || Platform.isWindows || Platform.isLinux;