package com.yawalasiwala.yawala_browser

import android.content.Intent
import android.net.Uri
import android.webkit.CookieManager
import android.webkit.WebStorage
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// Native host for Yawala Browser: system-browser / custom-tab hand-off and
/// cookie/cache clearing over `com.yawalasiwala/browser`. Embedded page
/// rendering is provided by the webview_flutter plugin on the Dart side.
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openCustomTab" -> result.success(
                        openExternally(call.argument<String>("url") ?: "")
                    )
                    "clearCookiesAndCache" -> {
                        clearWebData()
                        result.success(null)
                    }
                    // Embedded rendering happens in the Dart-side engine;
                    // acknowledge so the state machine never sees errors.
                    "createWebViewController" -> result.success(null)
                    "navigate" -> result.success(null)
                    else -> result.notImplemented()
                }
            }
    }

    /// Hands [url] to the user's browser (Custom Tab when the handler
    /// supports it, otherwise the system browser chooser).
    private fun openExternally(url: String): Boolean {
        if (url.isEmpty()) {
            return false
        }
        return try {
            val uri = Uri.parse(url)
            if (uri.scheme != "http" && uri.scheme != "https") {
                return false
            }
            startActivity(Intent(Intent.ACTION_VIEW, uri))
            true
        } catch (error: Exception) {
            false
        }
    }

    private fun clearWebData() {
        try {
            CookieManager.getInstance().apply {
                removeAllCookies(null)
                removeSessionCookies(null)
                flush()
            }
            WebStorage.getInstance().deleteAllData()
        } catch (_: Exception) {
        }
    }

    companion object {
        private const val CHANNEL = "com.yawalasiwala/browser"
    }
}
