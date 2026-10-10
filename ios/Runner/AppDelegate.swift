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
    registerScreenSecureChannel(engineBridge)
  }

  /// Kanal `einundzwanzig/screen` — iOS-Gegenstück zu FLAG_SECURE (M3).
  ///
  /// iOS kennt kein FLAG_SECURE. Der etablierte Weg: ein UITextField mit
  /// isSecureTextEntry als Overlay über dem Fenster — dessen Inhalt wird
  /// von Screenshots und Bildschirmaufnahmen ausgeblendet, und er deckt
  /// dann auch die übrige Ansicht ab. Solange `setSecure(true)` aktiv ist,
  /// erscheinen geheime Inhalte (nsec/ncryptsec) auf Aufnahmen geschwärzt.
  private var screenSecureField: UITextField?

  private func registerScreenSecureChannel(_ engineBridge: FlutterImplicitEngineBridge) {
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ScreenSecureChannel") else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "einundzwanzig/screen",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "setSecure":
        let on = (call.arguments as? [String: Any])?["on"] as? Bool ?? false
        self?.setScreenSecure(on)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func setScreenSecure(_ on: Bool) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      if on {
        if self.screenSecureField != nil { return }
        guard let window = self.window else { return }
        let field = UITextField(frame: window.bounds)
        field.isSecureTextEntry = true
        field.isUserInteractionEnabled = false
        field.backgroundColor = UIColor.black
        field.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        window.addSubview(field)
        // Der sichere Text des Feldes deckt das Fenster auf Aufnahmen ab —
        // aber nur wenn das Feld selbst "Inhalt" rendert. Ein leeres
        // secure-Feld schwärzt nichts; ein einzelnes Leerzeichen reicht.
        field.text = " "
        self.screenSecureField = field
      } else {
        self.screenSecureField?.removeFromSuperview()
        self.screenSecureField = nil
      }
    }
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
