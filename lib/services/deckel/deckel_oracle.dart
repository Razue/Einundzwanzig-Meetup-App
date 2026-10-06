// Die Frage, auf die am Tisch gewettet wird.
//
// Sie kommt nicht vom Tisch, sondern von einem Orakel: Kickstr legt sich für
// jede Stunde auf eine Ja/Nein-Frage fest ("Bitcoin um 13:00 bei oder über
// 86.000 USD?") und veröffentlicht dazu die SHA256-Hashes zweier Geheimnisse,
// eines für Ja, eines für Nein (kind 30237). Nach der Auflösung des
// Glimpse-Marktes veröffentlicht es genau eines der Geheimnisse (kind 30238).
//
// Der Tisch glaubt dem Orakel nicht aufs Wort: Eine Auflösung zählt nur,
// wenn ihr Geheimnis zum Hash der Festlegung passt.

import 'dart:async';
import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../app_logger.dart';
import '../relay_socket.dart';
import 'deckel_backend.dart';

const String _log = 'Deckel';

const int kOracleCommit = 30237;
const int kOracleReveal = 30238;

final _hex64 = RegExp(r'^[0-9a-f]{64}$');

class DeckelQuestion {
  /// Kennung der Festlegung. Eine Wette nennt sie.
  final String id;

  /// Der Glimpse-Markt hinter der Frage.
  final int topicId;

  /// "Bitcoin bei oder über [strike] USD?"
  final int strike;

  /// Wann der Markt schließt, Unix-Sekunden.
  final int closes;

  final String hashYes;
  final String hashNo;

  const DeckelQuestion({
    required this.id,
    required this.topicId,
    required this.strike,
    required this.closes,
    required this.hashYes,
    required this.hashNo,
  });
}

/// Was das Orakel gesagt hat, so weit es sich prüfen lässt.
class OracleBook {
  /// Festlegungen nach ihrer Kennung.
  final Map<String, DeckelQuestion> questions;

  /// Aufgelöste Fragen: Kennung der Festlegung und ob Ja eingetreten ist.
  final Map<String, bool> verdicts;

  const OracleBook({this.questions = const {}, this.verdicts = const {}});

  /// Liest Ereignisse des Orakels. Signaturen sind schon geprüft; hier fällt
  /// raus, was nicht vom Orakel stammt, die erwartete Form nicht hat, oder
  /// als Auflösung ein Geheimnis nennt, das nicht zur Festlegung passt.
  factory OracleBook.read(String oracle, Iterable<Map<String, dynamic>> events) {
    final questions = <String, DeckelQuestion>{};
    final reveals = <Map<String, dynamic>>[];
    for (final event in events) {
      if (event['pubkey'] != oracle || event['id'] is! String) continue;
      if (event['kind'] == kOracleReveal) {
        reveals.add(event);
        continue;
      }
      if (event['kind'] != kOracleCommit) continue;
      final topic = _tagOf(event, 'd')?.split(':');
      final strike = int.tryParse(_tagOf(event, 'strike') ?? '');
      final closes = int.tryParse(_tagOf(event, 'closes') ?? '');
      final yes = _tagOf(event, 'yes') ?? '';
      final no = _tagOf(event, 'no') ?? '';
      if (topic == null || topic.length != 2 || int.tryParse(topic[1]) == null) continue;
      if (strike == null || closes == null) continue;
      if (!_hex64.hasMatch(yes) || !_hex64.hasMatch(no) || yes == no) continue;
      final id = event['id'] as String;
      questions[id] = DeckelQuestion(
        id: id,
        topicId: int.parse(topic[1]),
        strike: strike,
        closes: closes,
        hashYes: yes,
        hashNo: no,
      );
    }

    final verdicts = <String, bool>{};
    for (final event in reveals) {
      final question = questions[_tagOf(event, 'e')];
      final outcome = _tagOf(event, 'outcome');
      final secret = _tagOf(event, 'preimage') ?? '';
      if (question == null || !_hex64.hasMatch(secret)) continue;
      final hash = sha256.convert(hex.decode(secret)).toString();
      if (outcome == 'yes' && hash == question.hashYes) verdicts[question.id] = true;
      if (outcome == 'no' && hash == question.hashNo) verdicts[question.id] = false;
    }
    return OracleBook(questions: questions, verdicts: verdicts);
  }

  /// Die Frage, auf die sich das Orakel zuletzt festgelegt hat und die noch
  /// offen ist. Ihr Strike ist am frischesten.
  DeckelQuestion? fresh(int now) {
    DeckelQuestion? best;
    for (final q in questions.values) {
      if (q.closes <= now || verdicts.containsKey(q.id)) continue;
      if (best == null || q.closes > best.closes) best = q;
    }
    return best;
  }
}

String? _tagOf(Map<String, dynamic> event, String name) {
  final tags = event['tags'];
  if (tags is! List) return null;
  for (final tag in tags) {
    if (tag is List && tag.length >= 2 && tag[0] == name && tag[1] is String) return tag[1] as String;
  }
  return null;
}

abstract class DeckelOracle {
  /// Schlüssel des Orakels, hex.
  String get pubkey;

  /// Festlegungen und Auflösungen des Orakels, jede auf Kennung und Signatur geprüft.
  Future<List<Map<String, dynamic>>> events();

  /// Welchen Anteil der Markt gerade Ja gibt, 0 bis 1. Null, wenn er nichts sagt.
  Future<double?> yesShare(DeckelQuestion question);
}

/// Das Orakel der Forecast-Instanz von Kickstr, wie sie zum Hackathon läuft.
class KickstrOracle implements DeckelOracle {
  KickstrOracle({
    this.relay = 'wss://kickstr-forecast.fly.dev/relay/websocket',
    this.pubkey = '3733f0300a9c274fba6d5e40b069c1f68fe4a2f3b2ea2891efa785e1027aa248',
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final String relay;

  @override
  final String pubkey;

  final http.Client _http;

  static const String _glimpse = 'https://main.bpmapi.io/api/v1/nmarket';
  static const Duration _timeout = Duration(seconds: 8);

  @override
  Future<List<Map<String, dynamic>>> events() async {
    final out = <Map<String, dynamic>>[];
    RelaySocket? ws;
    try {
      ws = await RelaySocket.connect(relay).timeout(_timeout);
      final done = Completer<void>();
      ws.listen(
        (data) {
          try {
            final msg = jsonDecode(data as String);
            if (msg is! List) return;
            if (msg.length >= 3 && msg[0] == 'EVENT') {
              final event = Map<String, dynamic>.from(msg[2] as Map);
              if (deckelEventValid(event)) out.add(event);
            } else if (msg.isNotEmpty && (msg[0] == 'EOSE' || msg[0] == 'CLOSED')) {
              if (!done.isCompleted) done.complete();
            }
          } catch (_) {}
        },
        onError: (_) {
          if (!done.isCompleted) done.complete();
        },
        onDone: () {
          if (!done.isCompleted) done.complete();
        },
      );
      ws.add(jsonEncode([
        'REQ',
        'oracle',
        {
          'kinds': [kOracleCommit, kOracleReveal],
          'authors': [pubkey],
          'limit': 80,
        },
      ]));
      await done.future.timeout(_timeout, onTimeout: () {});
    } catch (e) {
      AppLogger.debug(_log, 'Orakel nicht erreichbar: $e');
    } finally {
      try {
        ws?.close();
      } catch (_) {}
    }
    return out;
  }

  @override
  Future<double?> yesShare(DeckelQuestion question) async {
    try {
      final response = await _http
          .get(Uri.parse('$_glimpse/markets/${question.topicId}/quotes'))
          .timeout(_timeout);
      if (response.statusCode != 200) return null;
      return yesShareOf(jsonDecode(response.body), question.strike);
    } catch (_) {
      return null;
    }
  }
}

/// Anteil der Marktpreise auf Buckets, die bei oder über dem Strike beginnen.
double? yesShareOf(dynamic quotes, int strike) {
  if (quotes is! Map || quotes['outcomes'] is! List) return null;
  var yes = 0;
  var all = 0;
  for (final outcome in quotes['outcomes'] as List) {
    if (outcome is! Map) continue;
    final price = outcome['yes_price_millisats'];
    final from = num.tryParse('${outcome['name']}'.split('-').first);
    if (price is! int || from == null) continue;
    all += price;
    if (from >= strike) yes += price;
  }
  return all == 0 ? null : yes / all;
}

/// Ein Orakel im Speicher, für Tests und den Demo-Tisch.
class MemoryOracle implements DeckelOracle {
  MemoryOracle(this.pubkey);

  @override
  final String pubkey;

  final List<Map<String, dynamic>> published = [];
  double? share = 0.5;

  @override
  Future<List<Map<String, dynamic>>> events() async => List.of(published);

  @override
  Future<double?> yesShare(DeckelQuestion question) async => share;
}
