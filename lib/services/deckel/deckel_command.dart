// Gesprochener Deckel-Befehl, ohne Modell.
//
// Wie bei der Sprach-Wallet ist es eine feste Liste von Wörtern, deutsch
// und englisch. Die Zahl liest dieselbe Funktion wie dort.
//
//   "Runde 12600 für Bier"        eine Runde anschreiben
//   "4200 pro Kopf für Pizza"     Betrag je Kopf am Tisch
//   "Deckel"                      mein Stand
//   "Kassensturz"                 abrechnen
//   "Zahlen"                      meinen Rest begleichen
//   "Einlösen"                    einen Token scannen und quittieren
//   "Wette 2000 auf Ja"           auf die Frage des Orakels wetten

import '../voice_wallet/wallet_command.dart';

enum DeckelCommandKind {
  round,
  bet,
  balance,
  close,
  pay,
  redeem,
  confirm,
  cancel,
  help,
  unknown,
}

class DeckelCommand {
  final DeckelCommandKind kind;

  /// Bei einer Runde oder Wette, und nur wenn eine Zahl da war.
  final int? sats;

  /// Nur bei [DeckelCommandKind.bet]: wahr für Ja, falsch für Nein, null wenn ungesagt.
  final bool? yes;

  /// Bei einer Runde: die Zahl gilt pro Kopf.
  final bool perHead;

  /// Bei einer Runde: wofür, falls gesagt.
  final String subject;

  const DeckelCommand(this.kind, {this.sats, this.yes, this.perHead = false, this.subject = ''});

  static const unknown = DeckelCommand(DeckelCommandKind.unknown);
}

DeckelCommand parseDeckelCommand(String raw) {
  final text = _normalize(raw);
  if (text.isEmpty) return DeckelCommand.unknown;

  if (_confirm.contains(text)) return const DeckelCommand(DeckelCommandKind.confirm);
  if (_cancel.any((w) => text == w || text.startsWith('$w '))) {
    return const DeckelCommand(DeckelCommandKind.cancel);
  }
  if (_hasPhrase(text, _help)) return const DeckelCommand(DeckelCommandKind.help);

  // Eine Zahl im Satz heißt: anschreiben. "Eine Runde" ist keine Zahl.
  final sats = parseSpokenSats(_withoutArticles(text));
  if (_hasWord(text, _bet)) {
    // Das letzte Ja oder Nein im Satz ist die Seite: "Wette 2000 auf nein".
    final words = text.split(' ');
    final yesAt = words.lastIndexWhere(_betYes.contains);
    final noAt = words.lastIndexWhere(_betNo.contains);
    return DeckelCommand(
      DeckelCommandKind.bet,
      sats: sats,
      yes: yesAt < 0 && noAt < 0 ? null : yesAt > noAt,
    );
  }
  if (sats != null) {
    return DeckelCommand(
      DeckelCommandKind.round,
      sats: sats,
      perHead: _hasPhrase(text, _perHead),
      subject: _subjectOf(raw),
    );
  }

  if (_hasPhrase(text, _close)) return const DeckelCommand(DeckelCommandKind.close);
  if (_hasWord(text, _redeem) || text.split(' ').any((w) => w.startsWith('scan') || w.startsWith('skan'))) {
    return const DeckelCommand(DeckelCommandKind.redeem);
  }
  if (_hasWord(text, _pay)) return const DeckelCommand(DeckelCommandKind.pay);
  if (_hasWord(text, _round)) {
    return DeckelCommand(DeckelCommandKind.round, subject: _subjectOf(raw));
  }
  if (_hasPhrase(text, _balance)) return const DeckelCommand(DeckelCommandKind.balance);
  return DeckelCommand.unknown;
}

String _normalize(String raw) {
  var s = raw.toLowerCase().trim();
  s = s.replaceAll('ß', 'ss');
  s = s.replaceAll('ä', 'ae').replaceAll('ö', 'oe').replaceAll('ü', 'ue');
  s = s.replaceAll(RegExp(r',(?=\d{3}\b)'), '');
  s = s.replaceAll(RegExp(r"[^a-z0-9.\s]"), ' ');
  return s.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// "eine Runde", "a round", "einen Strich": der Artikel ist kein Betrag.
String _withoutArticles(String text) => text.replaceAll(
      RegExp(r'\b(eine|einen|ein|ne|a|an|one)\s+(?=(runde|round|strich|deckel|tab)\b)'),
      '',
    );

final _subject = RegExp(r'\b(?:für|fuer|for)\s+(.+)$', caseSensitive: false);
final _subjectTail = RegExp(
  r'\s*\b(pro kopf|pro nase|pro person|je kopf|each|per head|a head|sats?|satoshis?)\b.*$',
  caseSensitive: false,
);

String _subjectOf(String raw) {
  final match = _subject.firstMatch(raw.trim());
  if (match == null) return '';
  var subject = match.group(1)!.replaceAll(_subjectTail, '');
  subject = subject.replaceAll(RegExp(r'[\d.]+'), ' ').replaceAll(RegExp(r'[^\p{L}\s-]', unicode: true), ' ');
  subject = subject.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (subject.isEmpty) return '';
  if (subject.length > 40) subject = subject.substring(0, 40).trim();
  return subject[0].toUpperCase() + subject.substring(1);
}

const _confirm = {'ja', 'jawohl', 'yes', 'yeah', 'ok', 'okay', 'bestaetigen', 'confirm', 'klar', 'stimmt'};

const _cancel = {'nein', 'no', 'abbrechen', 'stop', 'stopp', 'cancel', 'zurueck'};

const _help = {'hilfe', 'help', 'befehle', 'commands', 'was kann ich', 'what can i'};

const _perHead = {'pro kopf', 'pro nase', 'pro person', 'je kopf', 'jeder', 'each', 'per head', 'a head'};

const _close = {
  'kassensturz',
  'abrechnen',
  'abrechnung',
  'rechnung',
  'settle',
  'close the tab',
  'close tab',
  'check please',
};

const _redeem = {'einloesen', 'einloese', 'empfangen', 'kamera', 'receive', 'redeem', 'camera'};

const _pay = {'zahlen', 'zahle', 'zahl', 'bezahlen', 'bezahle', 'begleichen', 'ausgleichen', 'pay'};

const _round = {'runde', 'round', 'anschreiben', 'strich'};

const _bet = {'wette', 'wetten', 'wett', 'bet', 'wager'};

const _betYes = {'ja', 'yes', 'drueber', 'ueber', 'darueber', 'hoeher', 'above', 'over', 'higher'};

const _betNo = {'nein', 'no', 'drunter', 'unter', 'darunter', 'tiefer', 'below', 'under', 'lower'};

const _balance = {
  'deckel',
  'saldo',
  'stand',
  'was steht',
  'wie viel',
  'wieviel',
  'schulde',
  'bekomme',
  'balance',
  'how much',
  'tab',
  'owe',
};

bool _hasPhrase(String text, Set<String> phrases) => phrases.any((p) => _hasWord(text, {p}));

bool _hasWord(String text, Set<String> words) => words.any((w) {
      return RegExp('(?:^|\\s)${RegExp.escape(w)}(?:\\s|\$)').hasMatch(text);
    });
