import Cocoa
import FlutterMacOS

/// Yawala Browser - macOS runner bootstrap.
class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    registerNativeBindingStubs(with: flutterViewController)
    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }

  /// Registers the `com.yawalasiwala/browser` method channel with
  /// safe-fallback responses until the real WKWebView integration lands.
  private func registerNativeBindingStubs(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "com.yawalasiwala/browser",
      binaryMessenger: messenger
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
}
