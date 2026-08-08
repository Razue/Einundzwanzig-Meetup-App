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
// Deshalb zweimal ausfuehren:
//   flutter test                     test/mempool_web_headers_test.dart
//   flutter test --platform chrome    test/mempool_web_headers_test.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:einundzwanzig_meetup_app/services/mempool.dart';

void main() {
  test('Cache-Control nur ausserhalb des Browsers', () {
    if (kIsWeb) {
      expect(MempoolService.noCacheHeaders, isEmpty,
          reason: 'im Web bricht Cache-Control die CORS-Anfrage');
    } else {
      expect(MempoolService.noCacheHeaders, contains('Cache-Control'),
          reason: 'nativ soll der CDN-Umweg weiter verhindert werden');
    }
  });

  test('User-Agent nur ausserhalb des Browsers', () {
    // Im Browser ist User-Agent ein verbotener Header — er wird ohnehin
    // verworfen. Weglassen vermeidet die Konsolenwarnung.
    if (kIsWeb) {
      expect(MempoolService.platformHeaders, isEmpty);
    } else {
      expect(MempoolService.platformHeaders, contains('User-Agent'));
    }
  });

  test('Cache-Buster nur im Web, vorhandene Parameter bleiben', () {
    final plain = Uri.parse('https://mempool.space/api/blocks/tip/height');
    final busted = MempoolService.cacheBusted(plain);

    if (kIsWeb) {
      expect(busted.queryParameters.containsKey('_'), isTrue,
          reason: 'ersetzt den Cache-Control-Header im Browser');
      expect(busted.path, plain.path);
    } else {
      expect(busted, plain, reason: 'nativ unveraendert');
    }

    // Ein bestehender Query-Parameter darf nicht verloren gehen.
    final withQuery = Uri.parse('https://mempool.space/api/x?a=1');
    final bustedQuery = MempoolService.cacheBusted(withQuery);
    expect(bustedQuery.queryParameters['a'], '1');
  });
}
