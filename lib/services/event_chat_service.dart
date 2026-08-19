// TERMIN-CHAT (NIP-22)
// ============================================
// Bewusst KEIN NIP-29-Raum wie beim Meetup-Chat.
//
// Ein Raum auf dem Gruppen-Relay ist ein verwaltetes Objekt: Er muss
// angelegt werden (kind 9007), verlangt eine Anmeldung und eine
// Berechtigung. Termine dagegen darf JEDER anlegen — auf den eigenen Relays
// dieser App, ohne Anmeldung. Wer einen Termin eintragen kann, muss auch
// darueber reden koennen; sonst haetten ausgerechnet die Termine, die
// jemand ohne Organisatoren-Rolle anlegt, keinen Chat.
//
// Deshalb: ein Kommentarstrang AM Termin nach NIP-22.
//
//   kind 1111 mit
//     ["A", "<kind>:<pubkey>:<d>"]   Wurzel — das Kalender-Event
//     ["K", "<kind>"]                Art der Wurzel
//     ["P", "<pubkey>"]              Ersteller der Wurzel
//     ["a"|"e"|"k"|"p", …]           unmittelbarer Bezug (hier = Wurzel
//                                    bei Beitraegen, sonst die Antwort)
//
// Grosse Buchstaben bezeichnen die WURZEL, kleine den unmittelbaren Bezug.
// Bei einem flachen Strang sind beide gleich; Antworten auf Antworten
// unterscheiden sich nur im kleinen Satz.
//
// Nebeneffekt, der uns nichts kostet: Jeder Nostr-Client, der NIP-22 kann,
// zeigt diese Beitraege als Kommentare am Termin an — auch Bens Oberflaeche,
// die NIP-22-Threads bereits nutzt.
// ============================================

import 'dart:async';
import 'dart:convert';

import 'app_logger.dart';
import 'chat_service.dart' show ChatMessage;
import 'news_reactions_service.dart';
import 'relay_socket.dart';
import 'signing_service.dart';

const String _tag = 'EventChat';

/// Kommentar-Ereignisart nach NIP-22.
const int _kComment = 1111;

class EventChatService {
  EventChatService._();

  static const Duration _timeout = Duration(seconds: 7);

  /// Laedt die Beitraege zu einem Termin, aelteste zuerst.
  ///
  /// Gefragt werden dieselben Relays wie fuer die News-Reaktionen: Dort
  /// liegen die Kalender-Events, und Beitraege gehoeren dorthin, wo die
  /// Wurzel liegt.
  static Future<List<ChatMessage>> loadMessages(String eventAddress) async {
    final relays = await NewsReactionsService.readTargets();
    final byId = <String, ChatMessage>{};

    // Alle Relays gleichzeitig fragen und ueber die Ereignis-ID entdoppeln —
    // dasselbe Ereignis kommt von mehreren zurueck.
    await Future.wait(relays.map((url) async {
      final events = await _query(url, {
        'kinds': [_kComment],
        '#A': [eventAddress],
        'limit': 200,
      });
      for (final e in events) {
        final m = ChatMessage.fromEvent(e);
        if (m != null) byId[m.id] = m;
      }
    }));

    final msgs = byId.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    AppLogger.debug(_tag, '${msgs.length} Beitraege zu $eventAddress.');
    return msgs;
  }

  /// Schreibt einen Beitrag. Gibt null zurueck bei Erfolg, sonst den Grund.
  static Future<String?> send({
    required String eventAddress,
    required String eventAuthorPubkey,
    required String text,
  }) async {
    final body = text.trim();
    if (body.isEmpty) return null;

    final parts = eventAddress.split(':');
    final rootKind = parts.isNotEmpty ? parts[0] : '31923';

    final SignedEvent signed;
    try {
      signed = await SigningService.signEvent(
        kind: _kComment,
        content: body,
        tags: [
          // Wurzel (gross)
          ['A', eventAddress],
          ['K', rootKind],
          if (eventAuthorPubkey.isNotEmpty) ['P', eventAuthorPubkey],
          // Unmittelbarer Bezug (klein) — bei einem flachen Strang dieselbe
          // Wurzel. Beide Saetze zu setzen ist keine Doppelung, sondern
          // Vorschrift: Ohne den kleinen Satz koennen Clients Beitrag und
          // Antwort nicht auseinanderhalten.
          ['a', eventAddress],
          ['k', rootKind],
          if (eventAuthorPubkey.isNotEmpty) ['p', eventAuthorPubkey],
        ],
      );
    } catch (e) {
      AppLogger.warn(_tag, 'Signieren fehlgeschlagen', e);
      return e.toString();
    }

    final relays = await NewsReactionsService.readTargets();
    final accepted = <String>[];
    final frame = signed.toEventMessage();

    await Future.wait(relays.map((url) async {
      if (await _publish(url, frame, signed.id)) accepted.add(url);
    }));

    AppLogger.debug(_tag,
        'Beitrag ${signed.id.substring(0, 8)}…: ${accepted.length} von ${relays.length} Relays angenommen');
    // Ein Relay genuegt. Auf alle zu warten hiesse auf das langsamste warten,
    // und ein Beitrag, der irgendwo liegt, ist geschrieben.
    return accepted.isEmpty ? 'Kein Relay hat den Beitrag angenommen' : null;
  }

  /// Offenes Abo fuer neue Beitraege. Gibt eine Beenden-Funktion zurueck.
  ///
  /// Nur EIN Relay wird abonniert — das erste erreichbare. Fuenf offene
  /// Verbindungen fuer einen Kommentarstrang waeren unverhaeltnismaessig,
  /// und beim Verlassen des Bildschirms muesste jede einzeln geschlossen
  /// werden.
  static Future<void Function()> subscribe(
    String eventAddress,
    void Function(ChatMessage) onMessage, {
    DateTime? since,
  }) async {
    final relays = await NewsReactionsService.readTargets();
    for (final url in relays) {
      try {
        final ws = await RelaySocket.connect(url)
            .timeout(const Duration(seconds: 4));
        ws.listen((data) {
          try {
            final msg = jsonDecode(data as String) as List<dynamic>;
            if (msg.length >= 3 && msg[0] == 'EVENT') {
              final m = ChatMessage.fromEvent(msg[2] as Map<String, dynamic>);
              if (m != null) onMessage(m);
            }
          } catch (_) {}
        }, onError: (_) {}, onDone: () {});

        ws.add(jsonEncode([
          'REQ',
          'evtchat',
          {
            'kinds': [_kComment],
            '#A': [eventAddress],
            if (since != null) 'since': since.millisecondsSinceEpoch ~/ 1000,
          }
        ]));
        AppLogger.debug(_tag, 'Abo laeuft ueber $url');
        return () {
          try {
            ws.close();
          } catch (_) {}
        };
      } catch (_) {
        // Naechstes Relay versuchen.
      }
    }
    // Keines erreichbar: Der Strang bleibt lesbar, nur nicht von selbst
    // aktuell.
    return () {};
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
      ws.add(jsonEncode(['REQ', 'q', filter]));
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
