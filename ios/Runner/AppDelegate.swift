import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerAppReviewChannel(engineBridge)
  }

  /// Kanal `einundzwanzig/review` fuer den App-Review-Demo-Login.
  ///
  /// `isTestFlight` prueft den Receipt: Bei TestFlight UND in
  /// App-Review-Sessions liegt ein Sandbox-Receipt vor, bei echten
  /// App-Store-Installationen nicht. Genau die beiden Faelle sollen den
  /// Demo-Login angeboten bekommen — AltStore-/Release-Nutzer nie.
  private func registerAppReviewChannel(_ engineBridge: FlutterImplicitEngineBridge) {
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "AppReviewChannel") else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "einundzwanzig/review",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "isTestFlight":
        let isSandbox = Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
        result(isSandbox)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
