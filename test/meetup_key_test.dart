// ============================================
// UNIT TESTS: MeetupKey — Meetup-Kennung im Badge
// ============================================
// Hintergrund: Frueher wurde jede Kennung am letzten Bindestrich zerlegt.
// Aus "bad-neuenahr" wurde Stadt "bad" + Land "NEUENAHR", und Organisator
// und Teilnehmer bildeten verschiedene Netzwerk-Kennungen.
//
// Geprueft wird:
//   - Zerlegung nur bei echtem ISO-Ländercode
//   - Zusammensetzen beim Organisator
//   - Organisator-Kennung == Teilnehmer-Kennung, auch bei Namen mit
//     mehreren Bindestrichen und Leerzeichen
//   - Rueckwaertskompatibilitaet: alte Kennungen ohne Land
// ============================================

import 'package:flutter_test/flutter_test.dart';
import 'package:einundzwanzig_meetup_app/services/badge_security.dart';
import 'package:einundzwanzig_meetup_app/services/meetup_key.dart';

void main() {
  group('MeetupKey.parse — nur echte Ländercodes werden abgetrennt', () {
    final cases = <String, List<String>>{
      // Kennung            → [Slug, Land]
      'bad-neuenahr': ['bad-neuenahr', ''],
      'frankfurt-am-main': ['frankfurt-am-main', ''],
      'rothenburg-ob-der-tauber': ['rothenburg-ob-der-tauber', ''],
      'köln-deutz': ['köln-deutz', ''],
      'neu-ulm': ['neu-ulm', ''],
      'aachen-de': ['aachen', 'DE'],
      'bad-neuenahr-de': ['bad-neuenahr', 'DE'],
      'koblenz-de': ['koblenz', 'DE'],
      'wien-at': ['wien', 'AT'],
      'zürich-ch': ['zürich', 'CH'],
      'aschaffenburg': ['aschaffenburg', ''],
      'frankfurt-am-main-de': ['frankfurt-am-main', 'DE'],
    };

    cases.forEach((input, expected) {
      test('$input → ${expected[0]} / "${expected[1]}"', () {
        final p = MeetupKey.parse(input);
        expect(p.slug, expected[0]);
        expect(p.country, expected[1]);
      });
    });

    test('bad-neuenahr wird NICHT in bad + NEUENAHR zerlegt', () {
      final p = MeetupKey.parse('bad-neuenahr');
      expect(p.slug, isNot('bad'));
      expect(p.country, isNot('NEUENAHR'));
    });

    test('frankfurt-am-main wird NICHT in frankfurt-am + MAIN zerlegt', () {
      final p = MeetupKey.parse('frankfurt-am-main');
      expect(p.slug, isNot('frankfurt-am'));
      expect(p.country, isNot('MAIN'));
    });

    test('Randfälle: leer, Bindestrich am Anfang/Ende', () {
      expect(MeetupKey.parse('').slug, '');
      expect(MeetupKey.parse('-de').slug, '-de');
      expect(MeetupKey.parse('aachen-').slug, 'aachen-');
    });
  });

  group('MeetupKey.compose — Organisator', () {
    test('hängt gültiges Land klein an', () {
      expect(MeetupKey.compose('bad-neuenahr', 'DE'), 'bad-neuenahr-de');
      expect(MeetupKey.compose('wien', 'at'), 'wien-at');
    });

    test('ohne oder mit ungültigem Land bleibt es beim Slug', () {
      expect(MeetupKey.compose('bad-neuenahr', ''), 'bad-neuenahr');
      expect(MeetupKey.compose('bad-neuenahr', 'Deutschland'), 'bad-neuenahr');
    });

    test('compose und parse sind umkehrbar', () {
      for (final city in [
        'Bad Neuenahr',
        'Frankfurt am Main',
        'Rothenburg ob der Tauber',
        'Neu-Ulm',
        'Köln-Deutz',
        'Aschaffenburg',
      ]) {
        final slug = MeetupKey.slug(city);
        final p = MeetupKey.parse(MeetupKey.compose(slug, 'DE'));
        expect(p.slug, slug, reason: city);
        expect(p.country, 'DE', reason: city);
      }
    });
  });

  group('MeetupKey.slug — unverändert gegenüber früher', () {
    test('entspricht der alten Organisator-Formel', () {
      for (final name in ['Aschaffenburg', 'Bad Neuenahr', 'Neu-Ulm', 'München']) {
        expect(MeetupKey.slug(name), name.toLowerCase().replaceAll(' ', '-'),
            reason: 'Bestehende Netzwerk-Kennungen muessen gueltig bleiben');
      }
    });
  });

  group('Organisator-Kennung == Teilnehmer-Kennung', () {
    final date = DateTime(2026, 10, 5);

    /// Was der Organisator veroeffentlicht (CoAttendanceService):
    /// Slug des Namens plus Datum.
    String organizerKey(String city) =>
        MeetupKey.eventId(MeetupKey.slug(city), date);

    /// Was der Teilnehmer aus dem gescannten Badge bildet
    /// (meetup_verification): Slug aus der signierten Kennung plus Datum.
    String participantKey(String m) {
      final normalized = BadgeSecurity.normalize({'v': 2, 't': 'B', 'm': m, 'b': 0});
      final slug = normalized['meetup_slug'] as String;
      return MeetupKey.eventId(slug, date);
    }

    for (final city in [
      'Bad Neuenahr',
      'Frankfurt am Main',
      'Rothenburg ob der Tauber',
      'Neu-Ulm',
      'Köln-Deutz',
      'Aschaffenburg',
      'Bad Neuenahr-Ahrweiler',
    ]) {
      test('$city — neuer Organisator (mit Land)', () {
        final m = MeetupKey.compose(MeetupKey.slug(city), 'DE');
        expect(participantKey(m), organizerKey(city));
      });

      test('$city — alter Organisator (ohne Land)', () {
        // Badges aelterer Organisator-Apps tragen nur den Slug. Auch die
        // muessen beim neuen Teilnehmer dieselbe Kennung ergeben.
        final m = MeetupKey.slug(city);
        expect(participantKey(m), organizerKey(city));
      });
    }

    test('alte Teilnehmer-App mit neuem Badge: Name ergibt denselben Slug', () {
      // Aeltere Apps zerlegen am letzten Bindestrich und bilden die Kennung
      // aus dem Namen. Mit dem Land am Ende landen sie beim richtigen Slug.
      final m = MeetupKey.compose(MeetupKey.slug('Bad Neuenahr'), 'DE');
      final parts = m.split('-');
      final oldCity = parts.sublist(0, parts.length - 1).join('-');
      final oldName = oldCity[0].toUpperCase() + oldCity.substring(1);
      expect(oldName.toLowerCase().replaceAll(' ', '-'), 'bad-neuenahr');
    });
  });

  group('BadgeSecurity.normalize — Anzeige und Kennung getrennt', () {
    test('bad-neuenahr-de: Slug, Land und Anzeigename', () {
      final n = BadgeSecurity.normalize({'v': 2, 't': 'B', 'm': 'bad-neuenahr-de', 'b': 0});
      expect(n['meetup_slug'], 'bad-neuenahr');
      expect(n['meetup_id'], 'bad-neuenahr');
      expect(n['meetup_country'], 'DE');
      expect(n['meetup_name'], 'Bad Neuenahr');
    });

    test('bad-neuenahr ohne Land bleibt ganz', () {
      final n = BadgeSecurity.normalize({'v': 2, 't': 'B', 'm': 'bad-neuenahr', 'b': 0});
      expect(n['meetup_slug'], 'bad-neuenahr');
      expect(n['meetup_country'], '');
    });

    test('Event-Badges sind nicht betroffen', () {
      final n = BadgeSecurity.normalize({
        'v': 2, 't': 'B',
        'm': 'evt:31923:${'a' * 64}:zitadelle:zitadelle-2026',
        'b': 0,
      });
      expect(n['is_event'], true);
      expect(n.containsKey('meetup_slug'), false);
    });
  });
}
