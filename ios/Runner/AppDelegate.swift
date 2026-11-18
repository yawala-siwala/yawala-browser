import Flutter
import UIKit

/// Yawala Browser - iOS runner bootstrap.
///
/// Registers the `com.yawalasiwala/browser` method channel so the Dart layer
/// can drive SFSafariViewController hand-offs, WKWebView engine attachment
/// and cookie/cache clearance (HTTPCookieStorage + URLCache). Values below
/// are safe-fallback stubs until the real web view integration lands.
@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "com.yawalasiwala/browser",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
        switch call.method {
        case "openCustomTab":
          result(false)
        case "createWebViewController":
          result(nil)
        case "navigate", "clearCookiesAndCache":
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
