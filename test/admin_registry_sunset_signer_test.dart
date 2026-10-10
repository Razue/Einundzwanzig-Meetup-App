// ============================================
// REGRESSIONSTEST — Sunset zählt SIGNER, nicht gelistete npubs
// ============================================
// Audit 2, Fund 6: Die Sunset-Zählung zählte früher Cache-Einträge statt
// Signierer. Eine Zwischenfassung der K1-Nachbereitung zählte die in einem
// Event GELISTETEN npubs — damit hätte ein einzelnes, korrekt signiertes
// Super-Admin-Event mit 20+ npubs Sunset sofort und dauerhaft ausgelöst:
// Der Super-Admin verliert seinen Status, jeder gelistete Pubkey wird zur
// gleichberechtigten Vertrauenswurzel.
//
// Hier wird abgesichert, dass nur UNTERSCHIEDLICHE Signer (event.pubkey)
// zählen. Schwelle: AdminRegistry.sunsetThreshold (20). Die Relay-Abfrage
// ist durch relayFetchOverride ersetzt — keine Verbindung wird aufgebaut.
// ============================================

import 'package:flutter_test/flutter_test.dart';
import 'package:nostr/nostr.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:einundzwanzig_meetup_app/services/admin_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final superHex = Nip19.decodePubkey(AdminRegistry.superAdminNpub);
  String freshNpub() => Nip19.encodePubkey(Keychain.generate().public);
  AdminEntry legit(String npub) =>
      AdminEntry(npub: npub, meetup: 'm', name: 'Admin');

  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => AdminRegistry.relayFetchOverride = null);

  test('EIN Signer mit 25 legitimen npubs zählt als EIN Autor — kein Sunset',
      () async {
    final listed = List.generate(25, (_) => freshNpub());
    AdminRegistry.relayFetchOverride = (_, _) async => {
          superHex: listed.map(legit).toList(),
        };

    // Fetch über checkAdmin (Schritt 4), Eintrag ist legitim → Admin.
    final result = await AdminRegistry.checkAdmin(listed.first);
    expect(result.isAdmin, isTrue);
    expect(result.source, 'nostr_relay');

    // 25 gelistete npubs, aber nur EIN Signer → Zähler steht bei 1.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('admin_unique_authors_count'), 1);
    expect(await AdminRegistry.isSunsetActive(), isFalse);
    expect(prefs.getBool('bootstrap_permanently_sunset'), isNot(isTrue));

    // Super-Admin behält seinen besonderen Status.
    final superResult =
        await AdminRegistry.checkAdmin(AdminRegistry.superAdminNpub);
    expect(superResult.source, 'super_admin');

    // Die 25 gelisteten Einträge sind trotzdem alle Admins.
    final list = await AdminRegistry.getAdminList();
    expect(list.map((e) => e.npub).toSet(), listed.toSet());
  });

  test('Bootstrap fragt nur den Super-Admin — fremde Signer lösen keinen Sunset aus',
      () async {
    expect(AdminRegistry.sunsetThreshold, 20);
    final strangers = List.generate(
        AdminRegistry.sunsetThreshold, (_) => Keychain.generate().public);
    List<String>? asked;
    AdminRegistry.relayFetchOverride = (_, authors) async {
      asked = List<String>.from(authors);
      return {
        for (final s in strangers) s: [legit(freshNpub())],
        superHex: [legit(freshNpub())],
      };
    };

    await AdminRegistry.fetchFromRelays();

    final prefs = await SharedPreferences.getInstance();
    expect(asked, [superHex]);
    // Zwanzig fremde Schlüssel plus der angefragte Super-Admin: gezählt
    // wird nur, wer angefragt wurde.
    expect(prefs.getInt('admin_unique_authors_count'), 1);
    expect(await AdminRegistry.isSunsetActive(), isFalse);
    expect(prefs.getBool('bootstrap_permanently_sunset'), isNot(isTrue));
  });
}
