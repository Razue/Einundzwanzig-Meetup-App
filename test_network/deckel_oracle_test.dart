// Das echte Orakel: Festlegungen und Auflösungen vom Kickstr-Relay, dazu der
// Ja-Anteil vom Glimpse-Markt. Braucht Netz:
//
//   flutter test test_network/deckel_oracle_test.dart

import 'package:einundzwanzig_meetup_app/services/deckel/deckel_oracle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Kickstr legt sich fest, löst auf, und die Geheimnisse passen', () async {
    final oracle = KickstrOracle();
    final events = await oracle.events();
    expect(events, isNotEmpty, reason: 'das Relay von kickstr-forecast.fly.dev antwortet');

    final book = OracleBook.read(oracle.pubkey, events);
    expect(book.questions, isNotEmpty);
    expect(book.verdicts, isNotEmpty, reason: 'mindestens eine Runde ist aufgelöst und geprüft');

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final open = book.fresh(now);
    // ignore: avoid_print
    print('Fragen: ${book.questions.length}, geprüfte Auflösungen: ${book.verdicts.length}');
    if (open == null) return; // zwischen zwei Runden gibt es kurz keine offene Frage
    final share = await oracle.yesShare(open);
    // ignore: avoid_print
    print('Offen: Bitcoin bei oder über ${open.strike} um ${DateTime.fromMillisecondsSinceEpoch(open.closes * 1000)}; Markt Ja ${share == null ? '–' : (share * 100).round()} %');
    expect(open.closes, greaterThan(now));
    expect(share, isNotNull);
    expect(share, inInclusiveRange(0, 1));
  }, timeout: const Timeout(Duration(seconds: 60)));
}
