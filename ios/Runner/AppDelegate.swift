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
  /// iOS hat kein FLAG_SECURE. Ein dauerhaftes schwarzes Feld oder ein
  /// umgehängter Secure-Text-Layer verdeckt die Ansicht oder bricht
  /// Tasten und Drehen. Stattdessen liegt die Abdeckung nur auf, während
  /// die App nicht aktiv ist: die Aufnahme im App-Umschalter zeigt dann
  /// Schwarz, der Nutzer sieht das Geheimnis, solange er in der App ist.
  /// `AppDelegate.window` ist unter dem Szenen-Lebenszyklus leer; das
  /// Fenster kommt aus der aktiven UIWindowScene.
  private var screenSecureEnabled = false
  private var privacyCover: UIView?
  private var screenSecureObserversInstalled = false
  /// Tokens behalten, sonst entfernt ARC die Beobachter sofort wieder.
  private var screenSecureObserverTokens: [NSObjectProtocol] = []

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
    installScreenSecureObservers()
  }

  private func installScreenSecureObservers() {
    if screenSecureObserversInstalled { return }
    screenSecureObserversInstalled = true
    let nc = NotificationCenter.default
    // queue: nil — der Block läuft synchron im Notification-Thread (Main),
    // bevor UIKit die Umschalter-Aufnahme macht. Eine Queue käme zu spät.
    screenSecureObserverTokens = [
      nc.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: nil) { [weak self] _ in
        self?.showPrivacyCoverIfNeeded()
      },
      nc.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { [weak self] _ in
        self?.hidePrivacyCover()
      },
    ]
  }

  private func foregroundWindow() -> UIWindow? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let scene = scenes.first { $0.activationState == .foregroundActive }
      ?? scenes.first { $0.activationState == .foregroundInactive }
      ?? scenes.first
    return scene?.windows.first { $0.isKeyWindow } ?? scene?.windows.first
  }

  private func setScreenSecure(_ on: Bool) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.screenSecureEnabled = on
      if !on {
        self.hidePrivacyCover()
      } else if UIApplication.shared.applicationState != .active {
        self.showPrivacyCoverIfNeeded()
      }
    }
  }

  private func showPrivacyCoverIfNeeded() {
    guard screenSecureEnabled, privacyCover == nil, let window = foregroundWindow() else { return }
    let cover = UIView(frame: window.bounds)
    cover.backgroundColor = .black
    cover.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    cover.isUserInteractionEnabled = true
    window.addSubview(cover)
    privacyCover = cover
  }

  private func hidePrivacyCover() {
    privacyCover?.removeFromSuperview()
    privacyCover = nil
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
