// ============================================
// REGRESSIONSTEST — Organische Alt-Claims (K1-Nachbereitung)
// ============================================
// Das Review der Cache-Bereinigung fand zwei Umgehungswege:
//   1. checkAdmin las den Cache direkt am Filter vorbei und erkannte einen
//      vergifteten "Organic (N Badges)"-Eintrag weiter als Admin (Quelle
//      local_cache) — damit auch checkAdminByPubkey, der Scanner und die
//      Event-Badge-Kette.
//   2. In Schritt 4 wurde die ROHE Relay-Liste durchsucht, bevor sie
//      gefiltert in den Cache ging (Quelle nostr_relay).
// Beides wird hier nachgestellt. Die Relay-Abfrage ist durch
// AdminRegistry.relayFetchOverride ersetzt — es wird keine Verbindung
// aufgebaut.
// ============================================

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nostr/nostr.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:einundzwanzig_meetup_app/services/admin_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final victim = Keychain.generate();
  final victimNpub = Nip19.encodePubkey(victim.public);
  final realNpub = Nip19.encodePubkey(Keychain.generate().public);

  Map<String, dynamic> entry(String npub, String name) => {
        'npub': npub,
        'meetup': 'aschaffenburg-de',
        'name': name,
        'added_at': 1,
      };

  tearDown(() {
    AdminRegistry.relayFetchOverride = null;
  });

  test('vergifteter Cache-Eintrag ist für checkAdmin kein Admin mehr', () async {
    SharedPreferences.setMockInitialValues({
      'admin_registry_cache': jsonEncode([
        entry(victimNpub, 'Organic (3 Badges)'),
        entry(realNpub, 'Ben'),
      ]),
      'admin_registry_timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    // Kein Relay antwortet → Schritt 4 endet mit 'unavailable', nie 'local_cache'.
    AdminRegistry.relayFetchOverride = (_, _) async => null;

    final result = await AdminRegistry.checkAdmin(victimNpub);
    expect(result.isAdmin, isFalse);
    expect(result.source, isNot('local_cache'));

    // Pubkey-Variante (Scanner, Event-Badge-Kette) läuft über denselben Weg.
    final byPubkey = await AdminRegistry.checkAdminByPubkey(victim.public);
    expect(byPubkey.isAdmin, isFalse);
    expect(byPubkey.source, isNot('local_cache'));

    // Gegenprobe: der echte Eintrag im selben Cache bleibt Admin.
    final real = await AdminRegistry.checkAdmin(realNpub);
    expect(real.isAdmin, isTrue);
    expect(real.source, 'local_cache');

    // Der vergiftete Eintrag ist beim Laden aus dem Cache entfernt worden.
    final prefs = await SharedPreferences.getInstance();
    final stored = jsonDecode(prefs.getString('admin_registry_cache')!) as List;
    expect(stored.map((e) => e['npub']), [realNpub]);
  });

  test('rohe Relay-Liste mit Organic-Eintrag macht in Schritt 4 niemanden zum Admin',
      () async {
    SharedPreferences.setMockInitialValues({});
    AdminRegistry.relayFetchOverride = (_, _) async => (
          admins: [
            AdminEntry(npub: victimNpub, meetup: 'x', name: 'Organic (3 Badges)'),
            AdminEntry(npub: realNpub, meetup: 'y', name: 'Ben'),
          ],
          uniqueAuthors: 1,
        );

    final result = await AdminRegistry.checkAdmin(victimNpub);
    expect(result.isAdmin, isFalse);
    expect(result.source, 'not_found');

    // Der echte Eintrag derselben Relay-Antwort kommt durch.
    final real = await AdminRegistry.checkAdmin(realNpub);
    expect(real.isAdmin, isTrue);

    // Und nur er liegt danach im Cache.
    final list = await AdminRegistry.getAdminList();
    expect(list.map((e) => e.npub), [realNpub]);
  });
}
