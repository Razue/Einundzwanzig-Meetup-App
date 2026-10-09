import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Screenshot-Sperre und kurzes Leben von Geheimnissen in der Zwischenablage.
///
/// Android setzt `FLAG_SECURE`, solange [set] mit true läuft. iOS und Web
/// kennen den Kanal nicht; dort bleibt nur das Leeren der Zwischenablage.
class ScreenSecure {
  static const _channel = MethodChannel('einundzwanzig/screen');
  static const _hold = Duration(seconds: 45);

  static Future<void> set(bool on) async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>('setSecure', {'on': on});
    } catch (_) {
      // iOS hat den Kanal nicht. Die Anzeige funktioniert trotzdem.
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
