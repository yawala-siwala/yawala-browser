package com.yawalasiwala.yawala_browser

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Yawala Browser - Android runner bootstrap.
 *
 * Registers the `com.yawalasiwala/browser` method channel so the Dart layer
 * can hand URLs off to Chrome Custom Tabs, attach embedded WebView engines
 * and clear cookies/cache (CookieManager + Cache). Values below are
 * safe-fallback stubs until the real Custom Tabs / WebView integration lands.
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openCustomTab" -> result.success(false)
                    "createWebViewController" -> result.success(null)
                    "navigate", "clearCookiesAndCache" -> result.success(null)
                    else -> result.notImplemented()
                }
            }
    }

    private companion object {
        const val CHANNEL = "com.yawalasiwala/browser"
    }
}
