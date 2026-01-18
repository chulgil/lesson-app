import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // NOTE: Custom MetronomePlugin disabled - using metronome package instead
    // The metronome package uses AVAudioEngine with looping buffer for sample-accurate timing
    // if let registrar = self.registrar(forPlugin: "MetronomePlugin") {
    //   MetronomePlugin.register(with: registrar)
    // }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
