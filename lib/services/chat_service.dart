// GRUPPEN-CHAT (NIP-29)
// ============================================
// Gegenstelle ist EIN Relay: wss://group.einundzwanzig.space. Es ist kein
// Webdienst mit Chat daran, sondern ein Nostr-Relay — Bens Weboberflaeche ist
// nur ein Client dafuer. Diese App wird ein zweiter, gleichberechtigter.
//
// Das Format stammt aus Bens Quelltext (einundzwanzig-group-package/js):
//
//   Raum          kind 39000, RELAY-signiert. Kennung = d-Tag, hier "h".
//   Meetup-Raum   zusaetzlich ["t","meetup"] und ["meetup_slug","<slug>"]
//   Nachricht     kind 9 mit ["h","<raum>"]
//   Beitreten     kind 9021 mit ["h","<raum>"]  -> Relay pflegt die Mitglieder
//   Mitglieder    kind 39002, d = h, p = Mitglieder (relay-autoritativ)
//   Raum anlegen  kind 9007, danach kind 9002 fuer Name/Beschreibung
//
// Wichtig zum Verstaendnis: Die Mitgliedschaft fuehrt das RELAY, nicht der
// Client. Wir fragen sie ab, wir behaupten sie nicht.
// ============================================

import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'app_logger.dart';
import 'relay_socket.dart';
import 'signing_service.dart';

const String _tag = 'Chat';

/// Das Space-Relay. Eine Konstante, weil die Raum-Kennungen nur hier gelten:
/// Dasselbe `h` auf einem anderen Relay ist ein anderer Raum.
const String kGroupRelay = 'wss://group.einundzwanzig.space';

// --- Ereignisarten nach NIP-29 ---
const int _kMessage = 9;
const int _kJoin = 9021;
const int _kLeave = 9022;
const int _kRoomCreate = 9007;
const int _kRoomEdit = 9002;
const int _kRoomMeta = 39000;
const int _kRoomMembers = 39002;

/// NIP-42: Antwort auf die Anmeldeaufforderung des Relays.
const int _kAuth = 22242;

/// Ein Raum, so wie ihn das Relay beschreibt.
class ChatRoom {
  /// Raum-Kennung (`h`). Nur zusammen mit dem Relay eindeutig.
  final String h;
  final String name;
  final String about;
  final String picture;

  /// Slug des Meetups, falls es ein Meetup-Raum ist.
  final String meetupSlug;

  /// Verweis auf ein Kalender-Event (`<kind>:<pubkey>:<d>`), falls es ein
  /// Event-Raum ist.
  final String eventAddress;

  const ChatRoom({
    required this.h,
    this.name = '',
    this.about = '',
    this.picture = '',
    this.meetupSlug = '',
    this.eventAddress = '',
  });

  bool get isMeetup => meetupSlug.isNotEmpty;
  bool get isEvent => eventAddress.isNotEmpty;

  static ChatRoom? fromEvent(Map<String, dynamic> event) {
    final tags = (event['tags'] as List?)?.cast<List>() ?? const [];
    String val(String key) {
      for (final t in tags) {
        if (t.isNotEmpty && t[0] == key && t.length > 1) return t[1].toString();
      }
      return '';
    }

    final h = val('d');
    if (h.isEmpty) return null;

    // Bindungs-Tag: ["i","meetup:<id>"] oder ["i","event:<adresse>"].
    var eventAddress = '';
    for (final t in tags) {
      if (t.isNotEmpty && t[0] == 'i' && t.length > 1) {
        final v = t[1].toString();
        if (v.startsWith('event:')) eventAddress = v.substring(6);
      }
    }

    return ChatRoom(
      h: h,
      name: val('name'),
      about: val('about'),
      picture: val('picture'),
      meetupSlug: val('meetup_slug'),
      eventAddress: eventAddress,
    );
  }
}

/// Eine Nachricht im Raum.
class ChatMessage {
  final String id;
  final String pubkey;
  final String content;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.pubkey,
    required this.content,
    required this.createdAt,
  });

  static ChatMessage? fromEvent(Map<String, dynamic> event) {
    final id = (event['id'] ?? '').toString();
    final pubkey = (event['pubkey'] ?? '').toString();
    final content = (event['content'] ?? '').toString();
    final ts = event['created_at'];
    if (id.isEmpty || pubkey.isEmpty || ts is! int) return null;
    return ChatMessage(
      id: id,
      pubkey: pubkey,
      content: content,
      createdAt: DateTime.fromMillisecondsSinceEpoch(ts * 1000),
    );
  }
}

class ChatService {
  ChatService._();

  static const Duration _timeout = Duration(seconds: 8);

  /// Zwischengespeicherte Raumliste.
  ///
  /// Das Dashboard fragt fuer jeden Favoriten nach dem Raum. Ohne Cache
  /// zoege es die komplette Raumliste mehrfach hintereinander vom Relay —
  /// bei vier Favoriten viermal. Die Liste aendert sich selten; fuenf Minuten
  /// sind ein guter Tausch zwischen Frische und Datenverkehr.
  static List<ChatRoom>? _roomCache;
  static DateTime? _roomCacheAt;
  static const Duration _cacheTtl = Duration(minutes: 5);

  /// Schluessel fuer den Lesestand: Raum -> Zeitstempel der letzten
  /// gesehenen Nachricht (Unix-Sekunden).
  static const String _readKey = 'chat_last_read';

  /// Baut eine Verbindung auf UND meldet sich an, falls das Relay es
  /// verlangt (NIP-42).
  ///
  /// Das Gruppen-Relay verlangt die Anmeldung schon zum LESEN — ohne sie
  /// liefert es schlicht nichts zurueck, ohne Fehlermeldung. Genau das war
  /// der Grund, warum die Raumliste leer blieb und der Chat-Knopf nichts tat.
  ///
  /// Ablauf: Das Relay schickt nach dem Verbinden `["AUTH", "<challenge>"]`.
  /// Darauf antworten wir mit einem signierten Ereignis der Art 22242, das
  /// Relay-Adresse und challenge traegt. Erst nach dessen Bestaetigung
  /// nimmt das Relay Abfragen und Ereignisse an.
  ///
  /// [onEvent] bekommt alle Nachrichten, die NICHT zur Anmeldung gehoeren —
  /// so muss keine Aufrufstelle die Anmeldung mitbehandeln.
  static Future<RelaySocket?> _connectAuthed(
    void Function(List<dynamic> msg) onEvent, {
    Duration authTimeout = const Duration(seconds: 6),
  }) async {
    final RelaySocket ws;
    try {
      ws = await RelaySocket.connect(kGroupRelay)
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      AppLogger.warn(_tag, 'Verbindung fehlgeschlagen', e);
      return null;
    }

    final ready = Completer<bool>();
    String? authEventId;

    ws.listen((data) {
      List<dynamic> msg;
      try {
        msg = jsonDecode(data as String) as List<dynamic>;
      } catch (_) {
        return;
      }
      if (msg.isEmpty) return;

      // --- Anmeldung ---
      if (msg[0] == 'AUTH' && msg.length >= 2 && msg[1] is String) {
        final challenge = msg[1] as String;
        () async {
          try {
            final signed = await SigningService.signEvent(
              kind: _kAuth,
              content: '',
              tags: [
                ['relay', kGroupRelay],
                ['challenge', challenge],
              ],
            );
            authEventId = signed.id;
            ws.add(jsonEncode(['AUTH', signed.toJson()]));
          } catch (e) {
            AppLogger.warn(_tag, 'Anmeldung konnte nicht signiert werden', e);
            if (!ready.isCompleted) ready.complete(false);
          }
        }();
        return;
      }

      // Bestaetigung der Anmeldung — erst danach ist die Verbindung nutzbar.
      if (msg[0] == 'OK' &&
          msg.length >= 3 &&
          authEventId != null &&
          msg[1] == authEventId) {
        final ok = msg[2] == true;
        AppLogger.debug(_tag,
            'Anmeldung ${ok ? "angenommen" : "abgelehnt: ${msg.length >= 4 ? msg[3] : ""}"}');
        if (!ready.isCompleted) ready.complete(ok);
        return;
      }

      onEvent(msg);
    }, onError: (_) {
      if (!ready.isCompleted) ready.complete(false);
    }, onDone: () {
      if (!ready.isCompleted) ready.complete(false);
    });

    // Manche Relays fordern gar nicht auf. Dann gilt die Verbindung nach
    // kurzer Wartezeit als nutzbar — laenger zu warten hiesse, gegen ein
    // Relay zu arbeiten, das gar nichts von uns will.
    Timer(const Duration(milliseconds: 900), () {
      if (!ready.isCompleted && authEventId == null) ready.complete(true);
    });

    final ok = await ready.future.timeout(authTimeout, onTimeout: () => false);
    if (!ok) {
      try {
        ws.close();
      } catch (_) {}
      return null;
    }
    return ws;
  }

  /// Fuehrt EINE Abfrage aus und sammelt die Ereignisse bis EOSE.
  ///
  /// Bewusst kein Dauer-Abo: Der Chat-Bildschirm haelt seine eigene offene
  /// Verbindung (siehe [subscribe]); alles Uebrige — Raumliste, Mitglieder —
  /// ist eine Momentaufnahme und soll die Verbindung nicht offen halten.
  static Future<List<Map<String, dynamic>>> _query(
    Map<String, dynamic> filter, {
    Duration timeout = _timeout,
  }) async {
    final out = <Map<String, dynamic>>[];
    final done = Completer<void>();

    final ws = await _connectAuthed((msg) {
      if (msg.length >= 3 && msg[0] == 'EVENT') {
        out.add(msg[2] as Map<String, dynamic>);
      } else if (msg[0] == 'EOSE') {
        if (!done.isCompleted) done.complete();
      } else if (msg[0] == 'CLOSED') {
        // Das Relay lehnt die Abfrage ab — meist "auth-required". Den Grund
        // protokollieren, sonst sucht man spaeter an der falschen Stelle.
        AppLogger.warn(_tag,
            'Abfrage abgelehnt: ${msg.length >= 3 ? msg[2] : "ohne Grund"}');
        if (!done.isCompleted) done.complete();
      }
    });
    if (ws == null) return out;

    try {
      ws.add(jsonEncode(['REQ', 'q', filter]));
      await done.future.timeout(timeout, onTimeout: () {});
    } catch (e) {
      AppLogger.warn(_tag, 'Abfrage fehlgeschlagen', e);
    } finally {
      try {
        ws.close();
      } catch (_) {}
    }
    return out;
  }

  /// Sendet ein signiertes Ereignis und wartet auf die OK-Antwort.
  static Future<String?> _publish(SignedEvent signed) async {
    final done = Completer<String?>();

    final ws = await _connectAuthed((msg) {
      // ["OK", <id>, <true|false>, <grund>]
      if (msg.length >= 3 && msg[0] == 'OK' && msg[1] == signed.id) {
        final ok = msg[2] == true;
        final reason = msg.length >= 4 ? msg[3].toString() : '';
        if (!done.isCompleted) done.complete(ok ? null : reason);
      }
    });
    if (ws == null) return 'Anmeldung am Relay fehlgeschlagen';

    try {
      ws.add(signed.toEventMessage());
      return await done.future
          .timeout(_timeout, onTimeout: () => 'Zeitüberschreitung');
    } catch (e) {
      AppLogger.warn(_tag, 'Senden fehlgeschlagen', e);
      return e.toString();
    } finally {
      try {
        ws.close();
      } catch (_) {}
    }
  }

  // ── Räume finden ───────────────────────────────────────────────────────

  /// Alle Meetup-Räume des Relays.
  ///
  /// [force] umgeht den Zwischenspeicher — fuer ein bewusstes Neuladen.
  static Future<List<ChatRoom>> loadMeetupRooms({bool force = false}) async {
    final cached = _roomCache;
    final at = _roomCacheAt;
    if (!force &&
        cached != null &&
        at != null &&
        DateTime.now().difference(at) < _cacheTtl) {
      return cached;
    }
    final fresh = await _loadMeetupRoomsUncached();
    // Eine leere Antwort NICHT zwischenspeichern: Sie kann auch heissen, dass
    // das Relay gerade nicht erreichbar war, und dann waere der Chat fuenf
    // Minuten lang scheinbar nicht vorhanden.
    if (fresh.isNotEmpty) {
      _roomCache = fresh;
      _roomCacheAt = DateTime.now();
    }
    return fresh;
  }

  static Future<List<ChatRoom>> _loadMeetupRoomsUncached() async {
    final events = await _query({
      'kinds': [_kRoomMeta],
      '#t': ['meetup'],
      'limit': 500,
    });
    final rooms = <String, ChatRoom>{};
    for (final e in events) {
      final room = ChatRoom.fromEvent(e);
      // Ersetzbare Ereignisse: Bei Doppeltem gewinnt das jüngste. Das Relay
      // liefert meist schon nur das aktuelle, verlassen darf man sich nicht.
      if (room != null) rooms[room.h] = room;
    }
    AppLogger.debug(_tag, '${rooms.length} Meetup-Räume geladen.');
    return rooms.values.toList();
  }

  /// Der Raum zu einem Meetup-Slug, sonst null.
  ///
  /// Der Slug ist der Schlüssel, weil das Portal die Quelle der Wahrheit ist:
  /// Der Raum trägt ihn, alles Weitere (Logo, Termine) kommt aus der
  /// Portal-Liste, die diese App ohnehin schon lädt.
  static Future<ChatRoom?> findMeetupRoom(String slug) async {
    if (slug.isEmpty) return null;
    final rooms = await loadMeetupRooms();
    for (final r in rooms) {
      if (r.meetupSlug.toLowerCase() == slug.toLowerCase()) return r;
    }
    AppLogger.debug(_tag, 'Kein Raum für Meetup-Slug "$slug".');
    return null;
  }

  /// Der Raum zu einem Meetup, gesucht ueber den STADTNAMEN.
  ///
  /// Noetig, weil diese App Meetups ueber die Stadt kennt (`homeMeetupId`),
  /// Bens Raeume aber einen Portal-Slug tragen ("einundzwanzig-saarbruecken").
  /// Statt eine zweite Zuordnungstabelle zu pflegen, wird verglichen: Der
  /// Slug endet praktisch immer auf die normalisierte Stadt.
  ///
  /// Umlaute werden dabei umgeschrieben — im Slug steht "saarbruecken", in
  /// der Stadt "Saarbrücken". Ohne diese Ersetzung faende man kein einziges
  /// deutsches Meetup.
  static Future<ChatRoom?> findRoomForCity(String city) async {
    final needle = _slugify(city);
    if (needle.isEmpty) return null;

    final rooms = await loadMeetupRooms();
    for (final r in rooms) {
      final slug = r.meetupSlug.toLowerCase();
      if (slug == needle || slug.endsWith('-$needle')) return r;
    }
    // Zweiter Versuch ueber den Anzeigenamen — manche Raeume haben einen
    // Slug, der nicht auf die Stadt endet.
    for (final r in rooms) {
      if (_slugify(r.name) == needle) return r;
    }
    AppLogger.debug(_tag, 'Kein Raum fuer Stadt "$city" (gesucht: $needle).');
    return null;
  }

  static String _slugify(String input) => input
      .toLowerCase()
      .replaceAll('ä', 'ae')
      .replaceAll('ö', 'oe')
      .replaceAll('ü', 'ue')
      .replaceAll('ß', 'ss')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');

  /// Der Raum zu einem Kalender-Event, sonst null.
  static Future<ChatRoom?> findEventRoom(String eventAddress) async {
    if (eventAddress.isEmpty) return null;
    final events = await _query({
      'kinds': [_kRoomMeta],
      '#i': ['event:$eventAddress'],
      'limit': 10,
    });
    for (final e in events) {
      final room = ChatRoom.fromEvent(e);
      if (room != null) return room;
    }
    return null;
  }

  // ── Lesestand und Ungelesenes ──────────────────────────────────────────

  /// Zeitstempel der zuletzt gesehenen Nachricht eines Raums (Unix-Sekunden).
  ///
  /// Rein LOKAL. Nostr kennt keinen Lesestand, und ihn zu veroeffentlichen
  /// waere auch unerwuenscht: Niemand muss im Netz nachlesen koennen, wann
  /// jemand zuletzt in einen Raum geschaut hat.
  static Future<Map<String, int>> _readMarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_readKey) ?? const <String>[];
      final out = <String, int>{};
      for (final entry in raw) {
        // Format "<h>|<sekunden>"
        final i = entry.lastIndexOf('|');
        if (i <= 0) continue;
        final ts = int.tryParse(entry.substring(i + 1));
        if (ts != null) out[entry.substring(0, i)] = ts;
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  /// Merkt sich, bis wohin gelesen wurde.
  static Future<void> markRead(String h, DateTime until) async {
    try {
      final marks = await _readMarks();
      final ts = until.millisecondsSinceEpoch ~/ 1000;
      // Nie zurueckdrehen: Ein aelterer Aufruf darf einen neueren Stand
      // nicht ueberschreiben.
      if ((marks[h] ?? 0) >= ts) return;
      marks[h] = ts;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
          _readKey, marks.entries.map((e) => '${e.key}|${e.value}').toList());
    } catch (e) {
      AppLogger.debug(_tag, 'Lesestand nicht gespeichert: $e');
    }
  }

  /// Wie viele ungelesene Nachrichten liegen in diesen Räumen?
  ///
  /// EINE Abfrage für alle Räume zusammen — der `#h`-Filter nimmt eine Liste.
  /// Pro Raum einzeln zu fragen hiesse bei vier Favoriten vier
  /// Verbindungsaufbauten beim Öffnen des Dashboards.
  ///
  /// Eigene Nachrichten zaehlen nicht mit: Was man selbst geschrieben hat,
  /// hat man gelesen.
  static Future<Map<String, int>> unreadCounts(List<String> hs) async {
    if (hs.isEmpty) return {};
    final marks = await _readMarks();
    final me = await SigningService.pubkeyHex();

    // Ab dem aeltesten Lesestand fragen. Räume ohne Lesestand bekommen ein
    // Fenster von sieben Tagen: Wer den Raum noch nie geoeffnet hat, soll
    // sehen, dass dort etwas los IST — aber nicht die Historie von Monaten
    // als "ungelesen" gemeldet bekommen.
    final fallback = DateTime.now()
            .subtract(const Duration(days: 7))
            .millisecondsSinceEpoch ~/
        1000;
    var since = fallback;
    for (final h in hs) {
      final m = marks[h] ?? fallback;
      if (m < since) since = m;
    }

    final events = await _query({
      'kinds': [_kMessage],
      '#h': hs,
      'since': since,
      'limit': 500,
    }, timeout: const Duration(seconds: 6));

    final counts = <String, int>{for (final h in hs) h: 0};
    for (final e in events) {
      final ts = e['created_at'];
      final pubkey = (e['pubkey'] ?? '').toString();
      if (ts is! int || (me != null && pubkey == me)) continue;

      final tags = (e['tags'] as List?)?.cast<List>() ?? const [];
      for (final tag in tags) {
        if (tag.isNotEmpty && tag[0] == 'h' && tag.length > 1) {
          final h = tag[1].toString();
          if (!counts.containsKey(h)) break;
          if (ts > (marks[h] ?? fallback)) counts[h] = counts[h]! + 1;
          break;
        }
      }
    }
    AppLogger.debug(_tag, 'Ungelesen: $counts');
    return counts;
  }

  // ── Mitgliedschaft ─────────────────────────────────────────────────────

  /// Bin ich Mitglied dieses Raums?
  ///
  /// Gefragt wird das RELAY (kind 39002). Die Liste dort ist die einzige
  /// verbindliche Auskunft — ein lokal gemerkter Beitritt sagt nichts
  /// darüber, ob das Relay ihn angenommen hat.
  static Future<bool> isMember(String h) async {
    final me = await SigningService.pubkeyHex();
    if (me == null) return false;
    final events = await _query({
      'kinds': [_kRoomMembers],
      '#d': [h],
      'limit': 5,
    });
    for (final e in events) {
      final tags = (e['tags'] as List?)?.cast<List>() ?? const [];
      for (final t in tags) {
        if (t.isNotEmpty && t[0] == 'p' && t.length > 1 && t[1] == me) {
          return true;
        }
      }
    }
    return false;
  }

  /// Tritt einem Raum bei. Gibt null zurück bei Erfolg, sonst den Grund.
  static Future<String?> join(String h) async {
    try {
      final signed = await SigningService.signEvent(
        kind: _kJoin,
        content: '',
        tags: [
          ['h', h]
        ],
      );
      final err = await _publish(signed);
      AppLogger.debug(_tag, 'Beitritt zu $h: ${err ?? "angenommen"}');
      return err;
    } catch (e) {
      return e.toString();
    }
  }

  static Future<String?> leave(String h) async {
    try {
      final signed = await SigningService.signEvent(
        kind: _kLeave,
        content: '',
        tags: [
          ['h', h]
        ],
      );
      return await _publish(signed);
    } catch (e) {
      return e.toString();
    }
  }

  // ── Nachrichten ────────────────────────────────────────────────────────

  /// Holt die jüngsten Nachrichten eines Raums, älteste zuerst.
  static Future<List<ChatMessage>> loadMessages(String h,
      {int limit = 100}) async {
    final events = await _query({
      'kinds': [_kMessage],
      '#h': [h],
      'limit': limit,
    });
    final msgs = <ChatMessage>[];
    for (final e in events) {
      final m = ChatMessage.fromEvent(e);
      if (m != null) msgs.add(m);
    }
    msgs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return msgs;
  }

  /// Offenes Abo für neue Nachrichten.
  ///
  /// Gibt eine Funktion zum Beenden zurück. Der Aufrufer MUSS sie aufrufen —
  /// sonst bleibt die Verbindung nach dem Verlassen des Bildschirms offen.
  static Future<void Function()> subscribe(
    String h,
    void Function(ChatMessage) onMessage, {
    DateTime? since,
  }) async {
    final ws = await _connectAuthed((msg) {
      if (msg.length >= 3 && msg[0] == 'EVENT') {
        final m = ChatMessage.fromEvent(msg[2] as Map<String, dynamic>);
        if (m != null) onMessage(m);
      }
    });
    // Ohne Anmeldung kein Abo — der Aufrufer bekommt eine Beenden-Funktion,
    // die nichts tut, statt einer Ausnahme mitten im Aufbau des Bildschirms.
    if (ws == null) return () {};

    ws.add(jsonEncode([
      'REQ',
      'live',
      {
        'kinds': [_kMessage],
        '#h': [h],
        if (since != null) 'since': since.millisecondsSinceEpoch ~/ 1000,
      }
    ]));

    return () {
      try {
        ws.close();
      } catch (_) {}
    };
  }

  /// Schreibt eine Nachricht in den Raum.
  static Future<String?> send(String h, String text) async {
    final body = text.trim();
    if (body.isEmpty) return null;
    try {
      final signed = await SigningService.signEvent(
        kind: _kMessage,
        content: body,
        tags: [
          ['h', h]
        ],
      );
      return await _publish(signed);
    } catch (e) {
      return e.toString();
    }
  }

  // ── Raum für ein Event anlegen ─────────────────────────────────────────

  /// Legt einen Raum für ein Kalender-Event an, falls es noch keinen gibt.
  ///
  /// Der Ablauf folgt Bens Client: erst 9007 (anlegen), dann 9002 (Name und
  /// Beschreibung), dann 9021 (der Ersteller tritt selbst bei). Die Kennung
  /// wird aus der Event-Adresse abgeleitet, damit jeder Client denselben Raum
  /// findet, ohne ihn suchen zu müssen.
  ///
  /// Ob das Relay 9007 von beliebigen Leuten annimmt, ist offen — falls nicht,
  /// kommt der Grund als Rückgabewert und die Oberfläche kann es sagen,
  /// statt still zu scheitern.
  static Future<ChatRoom?> ensureEventRoom({
    required String eventAddress,
    required String title,
    required String about,
    String picture = '',
  }) async {
    final existing = await findEventRoom(eventAddress);
    if (existing != null) return existing;

    final h = _eventRoomId(eventAddress);
    try {
      final create = await SigningService.signEvent(
        kind: _kRoomCreate,
        content: '',
        tags: [
          ['h', h]
        ],
      );
      final createErr = await _publish(create);
      // "already exists" ist kein Fehler — dann gehört der Raum schon jemandem
      // und wir wollen ohnehin nur hinein.
      if (createErr != null && !createErr.toLowerCase().contains('already')) {
        AppLogger.warn(_tag, 'Raum anlegen abgelehnt: $createErr');
        return null;
      }

      final meta = await SigningService.signEvent(
        kind: _kRoomEdit,
        content: '',
        tags: [
          ['h', h],
          ['name', title],
          if (about.isNotEmpty) ['about', about],
          if (picture.isNotEmpty) ['picture', picture],
          // Bindung an das Kalender-Event — daran findet ihn findEventRoom.
          ['i', 'event:$eventAddress'],
          ['t', 'event'],
        ],
      );
      await _publish(meta);
      await join(h);

      return ChatRoom(h: h, name: title, about: about, eventAddress: eventAddress);
    } catch (e) {
      AppLogger.warn(_tag, 'Event-Raum konnte nicht angelegt werden', e);
      return null;
    }
  }

  /// Kennung eines Event-Raums.
  ///
  /// Aus der Event-Adresse abgeleitet statt zufällig: So kommt jeder Client
  /// auf dieselbe Kennung, und ein zweiter Versuch legt keinen zweiten Raum
  /// an. Nur Kleinbuchstaben, Ziffern und Bindestriche — NIP-29 lässt für `h`
  /// keine Doppelpunkte zu.
  static String _eventRoomId(String eventAddress) {
    final parts = eventAddress.split(':');
    if (parts.length < 3) return 'evt-${eventAddress.hashCode.abs()}';
    final author = parts[1];
    final d = parts.sublist(2).join('-');
    final shortAuthor = author.length >= 8 ? author.substring(0, 8) : author;
    final clean = d.toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), '-');
    return 'evt-$shortAuthor-$clean';
  }
}
