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

  test('erst sunsetThreshold VERSCHIEDENE Signer aktivieren Sunset', () async {
    expect(AdminRegistry.sunsetThreshold, 20);
    final threshold = AdminRegistry.sunsetThreshold;

    // Erster Fetch: threshold-1 verschiedene Signer mit je einem Eintrag.
    final signers = List.generate(threshold - 1, (_) => Keychain.generate().public);
    AdminRegistry.relayFetchOverride = (_, _) async => {
          for (final s in signers) s: [legit(freshNpub())],
        };
    await AdminRegistry.checkAdmin(freshNpub());

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('admin_unique_authors_count'), threshold - 1);
    expect(await AdminRegistry.isSunsetActive(), isFalse);

    // Zweiter Fetch: ein weiterer, neuer Signer. Die Menge akkumuliert über
    // Fetches hinweg → Schwelle erreicht → Sunset aktiv.
    final twentieth = Keychain.generate().public;
    AdminRegistry.relayFetchOverride = (_, _) async => {
          twentieth: [legit(freshNpub())],
        };
    await AdminRegistry.fetchFromRelays();

    expect(prefs.getInt('admin_unique_authors_count'), threshold);
    expect(await AdminRegistry.isSunsetActive(), isTrue);
  });
}
