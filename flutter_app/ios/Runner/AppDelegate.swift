import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Set up badge method channel
    let controller = window?.rootViewController as! FlutterViewController
    let badgeChannel = FlutterMethodChannel(
      name: "com.dohbelisk.thedailies/badge",
      binaryMessenger: controller.binaryMessenger
    )

    badgeChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "clearBadge":
        UIApplication.shared.applicationIconBadgeNumber = 0
        result(nil)
      case "setBadge":
        if let args = call.arguments as? [String: Any],
           let count = args["count"] as? Int {
          UIApplication.shared.applicationIconBadgeNumber = count
          result(nil)
        } else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Count not provided", details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
