import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Read API key from environment or GeneratedConfig
    var googleMapsApiKey = ""
    if let path = Bundle.main.path(forResource: "GeneratedConfig", ofType: "plist"),
       let config = NSDictionary(contentsOfFile: path),
       let apiKey = config["GOOGLE_MAPS_API_KEY"] as? String {
      googleMapsApiKey = apiKey
    }
    GMSServices.provideAPIKey(googleMapsApiKey)
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
