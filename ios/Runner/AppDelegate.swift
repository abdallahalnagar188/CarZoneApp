import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyAnsK0I2lw7YP3qhUthMBtlsiJ31WVkPrY")
    // FlutterAppDelegate forwards notification callbacks to the plugins
    // (firebase_messaging, flutter_local_notifications); without this, iOS
    // never shows a notification while the app is in the foreground.
    UNUserNotificationCenter.current().delegate = self
    GeneratedPluginRegistrant.register(with: self)
    if let registrar = registrar(forPlugin: "LiveBookingController") {
      LiveBookingController.register(with: registrar.messenger())
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
