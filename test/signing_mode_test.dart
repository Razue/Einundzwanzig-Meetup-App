// Sichert die Modus-Speicherung ab, nachdem sie von zwei auf drei Werte
// erweitert wurde.
//
// Das Risiko liegt nicht bei NIP-07, sondern bei den BESTEHENDEN
// Installationen: wuerde ein gespeichertes 'amber' nach dem Umbau als
// 'local' gelesen, waere der Nutzer ohne Vorwarnung im falschen Modus — die
// App wuerde einen lokalen nsec erwarten, den es nie gab, und beim Backup
// einen leeren Schluessel exportieren.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:einundzwanzig_meetup_app/services/signing_service.dart';

const _modeKey = 'signing_mode';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('getMode liest bestehende Werte unveraendert', () {
    test("'amber' bleibt amber", () async {
      SharedPreferences.setMockInitialValues({_modeKey: 'amber'});
      expect(await SigningService.getMode(), SigningMode.amber);
      expect(await SigningService.isAmber, isTrue);
      expect(await SigningService.isNip07, isFalse);
    });

    test("'local' bleibt local", () async {
      SharedPreferences.setMockInitialValues({_modeKey: 'local'});
      expect(await SigningService.getMode(), SigningMode.local);
    });

    test('fehlender Wert ist local', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await SigningService.getMode(), SigningMode.local);
    });

    test('unbekannter Wert faellt auf local zurueck, statt zu werfen', () async {
      // Kann durch einen kuenftigen Modus oder einen manipulierten Eintrag
      // entstehen. local ist die sichere Annahme: die App fragt dann nach
      // einem Schluessel, statt eine Identitaet vorzutaeuschen.
      SharedPreferences.setMockInitialValues({_modeKey: 'irgendwas-neues'});
      expect(await SigningService.getMode(), SigningMode.local);
    });
  });

  group('nip07', () {
    test("wird als 'nip07' gespeichert und wieder gelesen", () async {
      SharedPreferences.setMockInitialValues({});
      // npub aus dem Beispiel im Repo — restoreNip07 dekodiert ihn.
      await SigningService.restoreNip07(
          'npub1lf0rga7j66uj6enae2mxezamz5nsz3vechhvmh25tcarn4u8qf5q534jzc');

      expect(await SigningService.getMode(), SigningMode.nip07);
      expect(await SigningService.isNip07, isTrue);
      expect(await SigningService.isAmber, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(_modeKey), 'nip07',
          reason: 'der gespeicherte Wert muss stabil bleiben');
    });

    test('canSign ist false, wenn keine Erweiterung antwortet', () async {
      SharedPreferences.setMockInitialValues({});
      await SigningService.restoreNip07(
          'npub1lf0rga7j66uj6enae2mxezamz5nsz3vechhvmh25tcarn4u8qf5q534jzc');
      // Im Test gibt es kein window.nostr — also darf die App nicht
      // behaupten, sie koenne signieren. Ein gemerkter pubkey allein reicht
      // nicht: die Erweiterung kann deinstalliert worden sein.
      expect(await SigningService.canSign(), isFalse);
    });

    test('disconnect setzt auf local zurueck und raeumt auf', () async {
      SharedPreferences.setMockInitialValues({});
      await SigningService.restoreNip07(
          'npub1lf0rga7j66uj6enae2mxezamz5nsz3vechhvmh25tcarn4u8qf5q534jzc');
      await SigningService.disconnectNip07();

      expect(await SigningService.getMode(), SigningMode.local);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('nip07_pubkey_hex'), isNull);
      expect(prefs.getString('nip07_npub'), isNull);
    });

    test('connect ohne Erweiterung meldet Missing, nicht Error', () async {
      // Der Unterschied zaehlt fuer die Oberflaeche: Missing bedeutet
      // "keine Erweiterung da" (Knopf ausblenden), Error waere ein roter
      // Balken fuer einen Zustand, an dem niemand schuld ist.
      final result = await Nip07NostrSigner.connect();
      expect(result, isA<Nip07ConnectMissing>());
    });
  });

  group('isExternalSigner', () {
    test('true bei amber und nip07, false bei local', () async {
      SharedPreferences.setMockInitialValues({_modeKey: 'amber'});
      expect(await SigningService.isExternalSigner, isTrue);

      SharedPreferences.setMockInitialValues({_modeKey: 'nip07'});
      expect(await SigningService.isExternalSigner, isTrue);

      SharedPreferences.setMockInitialValues({_modeKey: 'local'});
      expect(await SigningService.isExternalSigner, isFalse);
    });
  });
}
