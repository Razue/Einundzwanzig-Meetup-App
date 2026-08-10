// Sichert ab, dass im Browser KEIN `Cache-Control` gesendet wird.
//
// Der Header ist nicht CORS-safelisted und erzwingt einen Preflight;
// mempool.space antwortet auf OPTIONS mit 404. Folge war, dass jede
// mempool-Anfrage im Web scheiterte und getBlockHeight() still 0 lieferte —
// die Bitcoin-Kachel blieb tot, ohne sichtbaren Fehler.
//
// Der Test laeuft bewusst OHNE Netz: er prueft die Header-Zusammenstellung,
// nicht den Dienst. Ein Test gegen mempool.space wuerde die CI von einem
// fremden Server abhaengig machen.
//
// BEIDE Zweige laufen hier in einem gewoehnlichen VM-Lauf, weil die Helfer
// `isWeb` als Parameter nehmen. Vorher hing der Web-Zweig an `kIsWeb` und war
// nur mit `flutter test --platform chrome` erreichbar — was die CI nicht
// ausfuehrt. Der Zweig, der den Fehler ueberhaupt verursacht hatte, war damit
// der einzige ungepruefte.
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:einundzwanzig_meetup_app/services/mempool.dart';

void main() {
  group('Web-Zweig (der Fall, der CORS gebrochen hat)', () {
    test('kein Cache-Control', () {
      expect(MempoolService.noCacheHeaders(isWeb: true), isEmpty,
          reason: 'im Web bricht Cache-Control die CORS-Anfrage');
    });

    test('kein User-Agent', () {
      // Im Browser ist User-Agent ein verbotener Header — er wird ohnehin
      // verworfen. Weglassen vermeidet die Konsolenwarnung.
      expect(MempoolService.platformHeaders(isWeb: true), isEmpty);
    });

    test('Cache-Buster ersetzt den Header', () {
      final plain = Uri.parse('https://mempool.space/api/blocks/tip/height');
      final busted = MempoolService.cacheBusted(plain, isWeb: true);
      expect(busted.queryParameters.containsKey('_'), isTrue);
      expect(busted.path, plain.path);
      expect(busted.host, plain.host);
    });

    test('vorhandene Query-Parameter bleiben erhalten', () {
      final busted = MempoolService.cacheBusted(
          Uri.parse('https://mempool.space/api/x?a=1'), isWeb: true);
      expect(busted.queryParameters['a'], '1');
      expect(busted.queryParameters.containsKey('_'), isTrue);
    });
  });

  group('Native Zweig', () {
    test('Cache-Control bleibt, der CDN-Umweg wird weiter verhindert', () {
      expect(MempoolService.noCacheHeaders(isWeb: false),
          contains('Cache-Control'));
    });

    test('eigener User-Agent statt Dart-Default', () {
      final headers = MempoolService.platformHeaders(isWeb: false);
      expect(headers, contains('User-Agent'));
      expect(headers['User-Agent'], contains('21Meetup'),
          reason: 'der Dart-Default ist ein Bot-Signal fuer WAFs');
    });

    test('URL bleibt unveraendert', () {
      final plain = Uri.parse('https://mempool.space/api/blocks/tip/height');
      expect(MempoolService.cacheBusted(plain, isWeb: false), plain);
    });
  });

  group('Standardwert folgt der Plattform', () {
    // Ohne diese Pruefung koennte der Parameter richtig sein und die
    // Aufrufstellen trotzdem den falschen Zweig bekommen.
    test('ohne Argument entspricht es kIsWeb', () {
      expect(MempoolService.noCacheHeaders(),
          MempoolService.noCacheHeaders(isWeb: kIsWeb));
      expect(MempoolService.platformHeaders(),
          MempoolService.platformHeaders(isWeb: kIsWeb));

      final uri = Uri.parse('https://mempool.space/api/x');
      expect(MempoolService.cacheBusted(uri).queryParameters.containsKey('_'),
          kIsWeb);
    });
  });
}
