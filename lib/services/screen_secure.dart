import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Screenshot-Sperre, Geräteauthentifizierung und kurzes Leben von
/// Geheimnissen in der Zwischenablage (Security Audit M3).
///
/// Android setzt `FLAG_SECURE`. iOS legt über `einundzwanzig/screen` erst
/// beim Verlassen der App eine Abdeckung auf das Fenster, damit die
/// Umschalter-Aufnahme das Geheimnis nicht zeigt. Web kennt den Kanal
/// nicht; dort bleibt nur das Leeren der Zwischenablage.
class ScreenSecure {
  static const _channel = MethodChannel('einundzwanzig/screen');
  static const _hold = Duration(seconds: 45);

  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<void> set(bool on) async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>('setSecure', {'on': on});
    } catch (_) {
      // Kanal fehlt (älteres Build). Die Anzeige funktioniert trotzdem.
    }
  }

  /// Geräteauthentifizierung (PIN, Muster, Biometrie), bevor ein geheimer
  /// Schlüssel sichtbar wird. Liefert true bei bestätigter Identität.
  ///
  /// Fällt auf false, wenn das Gerät keine Authentifizierung kann oder der
  /// Nutzer abbricht. Bei einem Gerät ganz ohne Sperre erlauben wir den
  /// Zugriff — dort gibt es nichts zu prüfen.
  static Future<bool> authenticate({String reason = ''}) async {
    if (kIsWeb) return false;
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) {
        // Kein Geräteschutz eingerichtet — nichts zu prüfen.
        return true;
      }
      return await _auth.authenticate(
        localizedReason: reason.isEmpty
            ? 'Bitte Identität bestätigen'
            : reason,
        options: const AuthenticationOptions(
          // Auch Geräte-PIN/Muster zulassen, nicht nur Biometrie.
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } on PlatformException {
      // Nutzerabbruch oder vorübergehender Fehler -> nicht anzeigen.
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Kopiert [secret] und löscht die Zwischenablage wieder, falls dort
  /// nach [_hold] noch genau dieser Text steht.
  static Future<void> copySecret(String secret) async {
    await Clipboard.setData(ClipboardData(text: secret));
    Future<void>.delayed(_hold, () async {
      try {
        final now = await Clipboard.getData(Clipboard.kTextPlain);
        if (now?.text == secret) {
          await Clipboard.setData(const ClipboardData(text: ''));
        }
      } catch (_) {}
    });
  }
}
