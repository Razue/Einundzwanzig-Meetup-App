// ZUSAGEN ZU TERMINEN (NIP-52)
// ============================================
// Eine Zusage ist ein eigenes Nostr-Ereignis, kein Eintrag in dieser App:
//
//   kind 31925
//     ["a", "<kind>:<pubkey>:<d>"]   der Termin
//     ["d", "<eigene Kennung>"]      ersetzbar — eine Zusage je Termin
//     ["status", "accepted"|"declined"|"tentative"]
//     ["p", "<ersteller>"]           damit der Veranstalter es mitbekommt
//
// Warum der Standard und keine lokale Liste: So sieht der Veranstalter, wer
// kommt — und andere Nostr-Clients zeigen es ebenfalls an. Eine Zusage, die
// nur auf dem eigenen Geraet liegt, waere fuer niemanden ausser einem selbst
// von Nutzen.
//
// kind 31925 ist ERSETZBAR: Ein zweites Ereignis mit derselben d-Kennung
// ueberschreibt das erste. Aus einer Zusage wird damit eine Absage, ohne
// dass etwas geloescht werden muesste — Loeschen kennt Nostr ohnehin nur
// als Bitte, nicht als Befehl.
// ============================================

import 'dart:async';
import 'dart:convert';

import 'app_logger.dart';
import 'news_reactions_service.dart';
import 'relay_socket.dart';
import 'signing_service.dart';

const String _tag = 'RSVP';
const int _kRsvp = 31925;

enum RsvpStatus { accepted, declined, tentative }

class EventRsvpService {
  EventRsvpService._();

  static const Duration _timeout = Duration(seconds: 7);

  /// Kennung der Zusage zu einem Termin.
  ///
  /// Aus der Termin-Adresse abgeleitet, damit eine zweite Antwort dieselbe
  /// Kennung traegt und die erste ersetzt. Zufaellig gewuerfelt haette jede
  /// Meinungsaenderung eine weitere Zusage hinterlassen.
  static String _dTag(String eventAddress) {
    final clean = eventAddress
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return 'rsvp-$clean';
  }

  /// Setzt oder aendert die eigene Antwort. Null bei Erfolg, sonst der Grund.
  static Future<String?> setStatus({
    required String eventAddress,
    required String eventAuthorPubkey,
    required RsvpStatus status,
  }) async {
    final SignedEvent signed;
    try {
      signed = await SigningService.signEvent(
        kind: _kRsvp,
        content: '',
        tags: [
          ['a', eventAddress],
          ['d', _dTag(eventAddress)],
          ['status', status.name],
          if (eventAuthorPubkey.isNotEmpty) ['p', eventAuthorPubkey],
        ],
      );
    } catch (e) {
      AppLogger.warn(_tag, 'Signieren fehlgeschlagen', e);
      return e.toString();
    }

    final relays = await NewsReactionsService.readTargets();
    final frame = signed.toEventMessage();
    var accepted = 0;
    await Future.wait(relays.map((url) async {
      if (await _publish(url, frame, signed.id)) accepted++;
    }));

    AppLogger.debug(_tag,
        'Antwort "${status.name}" zu $eventAddress: $accepted von ${relays.length} Relays');
    return accepted == 0 ? 'Kein Relay hat die Antwort angenommen' : null;
  }

  /// Eigene Antworten zu allen Terminen — Adresse zu Status.
  ///
  /// Gefragt wird nach dem EIGENEN Pubkey, nicht nach einzelnen Terminen:
  /// Eine Abfrage liefert alles, und die Zahl der Zusagen bleibt ueberschaubar.
  static Future<Map<String, RsvpStatus>> loadMine() async {
    final me = await SigningService.pubkeyHex();
    if (me == null) return {};

    final relays = await NewsReactionsService.readTargets();
    // Adresse -> (Zeitstempel, Status). Der Zeitstempel entscheidet bei
    // Doppeltem: Ersetzbare Ereignisse koennen in aelteren Fassungen noch
    // auf einem Relay liegen.
    final newest = <String, (int, RsvpStatus)>{};

    await Future.wait(relays.map((url) async {
      final events = await _query(url, {
        'kinds': [_kRsvp],
        'authors': [me],
        'limit': 300,
      });
      for (final e in events) {
        final ts = e['created_at'];
        if (ts is! int) continue;
        final tags = (e['tags'] as List?)?.cast<List>() ?? const [];

        String address = '';
        String status = '';
        for (final t in tags) {
          if (t.length >= 2 && t[0] == 'a') address = t[1].toString();
          if (t.length >= 2 && t[0] == 'status') status = t[1].toString();
        }
        if (address.isEmpty) continue;

        final parsed = RsvpStatus.values
            .where((s) => s.name == status)
            .firstOrNull;
        if (parsed == null) continue;

        final known = newest[address];
        if (known == null || ts > known.$1) newest[address] = (ts, parsed);
      }
    }));

    final out = {for (final e in newest.entries) e.key: e.value.$2};
    AppLogger.debug(_tag, '${out.length} eigene Antworten geladen.');
    return out;
  }

  // ── Hilfsmittel ────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> _query(
      String url, Map<String, dynamic> filter) async {
    final out = <Map<String, dynamic>>[];
    RelaySocket? ws;
    try {
      ws = await RelaySocket.connect(url).timeout(const Duration(seconds: 4));
      final done = Completer<void>();
      ws.listen((data) {
        try {
          final msg = jsonDecode(data as String) as List<dynamic>;
          if (msg.length >= 3 && msg[0] == 'EVENT') {
            out.add(msg[2] as Map<String, dynamic>);
          } else if (msg.isNotEmpty &&
              (msg[0] == 'EOSE' || msg[0] == 'CLOSED')) {
            if (!done.isCompleted) done.complete();
          }
        } catch (_) {}
      }, onError: (_) {
        if (!done.isCompleted) done.complete();
      }, onDone: () {
        if (!done.isCompleted) done.complete();
      });
      ws.add(jsonEncode(['REQ', 'rsvp', filter]));
      await done.future.timeout(_timeout, onTimeout: () {});
    } catch (_) {
      // Ein stummes Relay darf die uebrigen nicht aufhalten.
    } finally {
      try {
        ws?.close();
      } catch (_) {}
    }
    return out;
  }

  static Future<bool> _publish(String url, String frame, String id) async {
    RelaySocket? ws;
    try {
      ws = await RelaySocket.connect(url).timeout(const Duration(seconds: 4));
      final done = Completer<bool>();
      ws.listen((data) {
        try {
          final msg = jsonDecode(data as String) as List<dynamic>;
          if (msg.length >= 3 && msg[0] == 'OK' && msg[1] == id) {
            if (!done.isCompleted) done.complete(msg[2] == true);
          }
        } catch (_) {}
      }, onError: (_) {
        if (!done.isCompleted) done.complete(false);
      }, onDone: () {
        if (!done.isCompleted) done.complete(false);
      });
      ws.add(frame);
      return await done.future.timeout(_timeout, onTimeout: () => false);
    } catch (_) {
      return false;
    } finally {
      try {
        ws?.close();
      } catch (_) {}
    }
  }
}
