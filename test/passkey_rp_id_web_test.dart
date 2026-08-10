// Der kIsWeb-Zweig von PasskeyPrfService laeuft auf der Dart-VM NIE. Ohne
// diesen Test ist die Host-Erlaubnisliste eine Behauptung: sie wird nur im
// Browser ausgewertet, und dort haengt sie an `Uri.base`.
//
// Lauf: flutter test --platform chrome test/passkey_rp_id_web_test.dart
@TestOn('browser')
library;

import 'package:einundzwanzig_meetup_app/services/passkey_prf_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rpId ist im Browser der Host', () {
    expect(PasskeyPrfService.relyingPartyId(), Uri.base.host);
  });

  test('Testlauf auf localhost ist erlaubt', () {
    // Wenn das kippt, ist die Entwicklung auf localhost mitblockiert — dann
    // faellt es hier auf und nicht erst beim Ausprobieren im Browser.
    expect(Uri.base.host, anyOf('localhost', '127.0.0.1'));
    expect(PasskeyPrfService.isEnvironmentAllowed, isTrue);
  });

  test('ein github.io-Host wuerde abgelehnt', () {
    // Direkt pruefbar ist nur der aktuelle Host, deshalb hier die Liste selbst:
    // `contains` ist der einzige Weg, auf dem ein Host durchkommt.
    expect(PasskeyPrfService.allowedWebHosts.contains('razue.github.io'),
        isFalse);
  });
}
