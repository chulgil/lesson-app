import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Register custom MetronomePlugin BEFORE GeneratedPluginRegistrant
    // to avoid duplicate registration
    if let registrar = self.registrar(forPlugin: "app.lessonaza.metronome") {
      MetronomePlugin.register(with: registrar)
    }

    GeneratedPluginRegistrant.register(with: self)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
