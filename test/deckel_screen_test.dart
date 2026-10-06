import 'package:einundzwanzig_meetup_app/l10n/app_localizations.dart';
import 'package:einundzwanzig_meetup_app/screens/deckel_screen.dart';
import 'package:einundzwanzig_meetup_app/services/deckel/deckel_backend.dart';
import 'package:einundzwanzig_meetup_app/services/deckel/deckel_ledger.dart';
import 'package:einundzwanzig_meetup_app/services/speech/on_device_speech.dart';
import 'package:einundzwanzig_meetup_app/services/speech/on_device_voice.dart';
import 'package:einundzwanzig_meetup_app/services/voice_wallet/cashu_wallet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_cashu_mint.dart';

/// Ein Mikrofon, dem der Test die Wörter in den Mund legt.
class _FakeSpeech implements OnDeviceSpeech {
  void Function(String words, bool isFinal)? _onWords;
  int listens = 0;

  @override
  Future<SpeechFailure?> listen({
    required String localeId,
    required void Function(String words, bool isFinal) onWords,
  }) async {
    listens++;
    _onWords = onWords;
    return null;
  }

  @override
  Future<void> stop() async {}

  void say(String words) => _onWords!(words, true);
}

class _FakeVoice implements OnDeviceVoice {
  final spoken = <String>[];

  @override
  Future<void> speak(String text, {required String languageCode}) async => spoken.add(text);

  @override
  Future<void> stop() async {}
}

const _pace = Duration(milliseconds: 50);

Widget _app(Widget home) => MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

String _hero(WidgetTester tester) => tester.widget<Text>(find.byKey(const Key('deckel-hero'))).data!;

String _line(WidgetTester tester) => tester.widget<Text>(find.byKey(const Key('deckel-line'))).data!;

/// Lässt Ereignisse durchlaufen und die Demo-Gäste [steps] Schritte tun.
Future<void> _wait(WidgetTester tester, [int steps = 1]) async {
  for (var i = 0; i < steps; i++) {
    await tester.pump(_pace);
    await tester.pump();
  }
  await tester.pump();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Ohne Tisch: neuer Deckel, scannen oder Demo-Tisch', (tester) async {
    await tester.pumpWidget(_app(DeckelScreen(speech: _FakeSpeech(), voice: _FakeVoice())));
    await tester.pumpAndSettle();

    expect(find.text('Neuer Deckel'), findsOneWidget);
    expect(find.text('Deckel scannen'), findsOneWidget);
    expect(find.text('Demo-Tisch'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Demo-Tisch: der ganze Abend mit der Stimme', (tester) async {
    tester.view.physicalSize = const Size(1206, 2622);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final speech = _FakeSpeech();
    final voice = _FakeVoice();
    await tester.pumpWidget(
      _app(DeckelScreen(demo: true, demoPace: _pace, speech: speech, voice: voice)),
    );
    await _wait(tester, 5);

    // Anna und Ben sitzen und haben Bier und Pizza ausgelegt.
    expect(find.text('Anna'), findsOneWidget);
    expect(find.text('Ben'), findsOneWidget);
    expect(find.text('Bier'), findsOneWidget);
    expect(find.text('Pizza'), findsOneWidget);
    expect(_hero(tester), '7.200');
    expect(find.text('schuldest du'), findsOneWidget);

    // "Runde 6000 für Taxi" – die Seite fragt nach, "ja" schreibt an.
    await tester.tap(find.byKey(const Key('deckel-mic')));
    await tester.pump();
    speech.say('Runde 6000 für Taxi');
    await _wait(tester);
    expect(_line(tester), '6.000 Sats für alle 3 am Tisch?');
    expect(find.byKey(const Key('deckel-answer-yes')), findsOneWidget);
    expect(speech.listens, 2, reason: 'nach einer Frage hört die Seite wieder zu');

    speech.say('ja');
    await _wait(tester);
    expect(find.text('Taxi'), findsOneWidget);
    expect(_hero(tester), '3.200');
    expect(voice.spoken.last, contains('Angeschrieben'));

    // "Kassensturz" – aus sechs Schulden werden zwei Zahlungen.
    await tester.tap(find.byKey(const Key('deckel-mic')));
    await tester.pump();
    speech.say('Kassensturz');
    await _wait(tester);
    expect(_line(tester), 'Kassensturz über 3 Runden?');
    await tester.tap(find.byKey(const Key('deckel-answer-yes')));
    await _wait(tester);

    expect(find.text('6 Schulden · 18.400 Sats'), findsOneWidget);
    expect(find.text('2 Zahlungen · 3.400 Sats'), findsOneWidget);
    expect(find.text('Du → Anna'), findsOneWidget);
    expect(find.text('Ben → Anna'), findsOneWidget);
    expect(_line(tester), 'Aus 6 Schulden werden 2 Zahlungen.');

    // Ben zahlt von selbst an Anna.
    await _wait(tester, 2);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

    // Ich zahle: der Token erscheint als QR, Anna scannt, die Quittung kommt.
    await tester.tap(find.text('Zahlen'));
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
    expect(find.text('3.200 Sats an Anna'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('Lass Anna diesen Code scannen.'), findsOneWidget);

    await _wait(tester, 3);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Angekommen und quittiert.'), findsOneWidget);
    expect(find.text('Alles beglichen.'), findsOneWidget);
    expect(_hero(tester), '0');
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Demo-Tisch: die Frage des Orakels steht da, die Wette per Stimme wird zur Schuld', (tester) async {
    tester.view.physicalSize = const Size(1206, 2622);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final speech = _FakeSpeech();
    final voice = _FakeVoice();
    await tester.pumpWidget(
      _app(DeckelScreen(demo: true, demoPace: _pace, speech: speech, voice: voice)),
    );
    await _wait(tester, 5);

    // Option B: die Frage und was der Markt sagt.
    expect(find.text('FRAGE DES ORAKELS'), findsOneWidget);
    expect(find.textContaining('bei oder über 86.000 USD?'), findsOneWidget);
    expect(find.text('Markt: Ja 55 %'), findsOneWidget);
    expect(_hero(tester), '7.200');

    // Ohne Seite fragt die Seite nach, wie es geht.
    await tester.tap(find.byKey(const Key('deckel-mic')));
    await tester.pump();
    speech.say('Wette 2000');
    await _wait(tester);
    expect(_line(tester), 'Sag: Wette 2000 auf Ja. Oder auf Nein.');

    // "Wette 2000 auf Ja" – nachfragen, "ja", dann steht sie.
    await tester.tap(find.byKey(const Key('deckel-mic')));
    await tester.pump();
    speech.say('Wette 2000 auf Ja');
    await _wait(tester);
    expect(_line(tester), startsWith('2.000 Sats auf Ja: Bitcoin um '));
    expect(_line(tester), endsWith(' bei oder über 86.000?'));
    speech.say('ja');
    for (var i = 0; i < 8; i++) {
      await tester.pump();
    }
    expect(_line(tester), 'Wette steht. Jetzt muss jemand dagegen halten.');
    expect(find.text('Du: 2.000 auf Ja · sucht Gegenseite'), findsOneWidget);

    // Ben hält dagegen.
    await _wait(tester, 2);
    expect(find.textContaining('Du Ja ↔ Ben Nein · 2.000 · wartet auf '), findsOneWidget);
    expect(_hero(tester), '7.200', reason: 'vor der Auflösung schuldet niemand etwas');

    // Das Orakel löst auf: Ja. Ben schuldet mir 2.000.
    await _wait(tester, 4);
    expect(find.text('Wette: 86.000 oder mehr?'), findsOneWidget);
    expect(find.text('Du hast gewonnen'), findsOneWidget);
    expect(_hero(tester), '5.200');
    expect(find.text('FRAGE DES ORAKELS'), findsNothing, reason: 'die Frage ist entschieden');
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Demo-Tisch: ohne Runde kein Kassensturz, ohne Kassensturz kein Zahlen', (tester) async {
    final speech = _FakeSpeech();
    final voice = _FakeVoice();
    await tester.pumpWidget(
      _app(DeckelScreen(demo: true, demoPace: _pace, speech: speech, voice: voice)),
    );
    await _wait(tester);

    await tester.tap(find.byKey(const Key('deckel-mic')));
    await tester.pump();
    speech.say('Kassensturz');
    await _wait(tester);
    expect(_line(tester), 'Es ist nichts angeschrieben.');

    await tester.tap(find.byKey(const Key('deckel-mic')));
    await tester.pump();
    speech.say('Guten Abend zusammen');
    await _wait(tester);
    expect(_line(tester), 'Das habe ich nicht verstanden.');

    await tester.tap(find.byKey(const Key('deckel-mic')));
    await tester.pump();
    // Inzwischen haben die Gäste ausgelegt: zahlen geht erst nach dem Kassensturz.
    await _wait(tester, 4);
    speech.say('zahlen');
    await _wait(tester);
    expect(_line(tester), 'Erst Kassensturz, dann zahlen.');
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Echter Tisch: nach dem Scan Platz nehmen, allein zeigt die Seite den Bierdeckel', (tester) async {
    tester.view.physicalSize = const Size(1206, 2622);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final backend = MemoryDeckelBackend();
    final mint = FakeCashuMint();
    await tester.pumpWidget(
      _app(
        DeckelScreen(
          join: (deckelId: 'a1b2c3d4e5f60718', name: 'Stammtisch Berlin'),
          backend: backend,
          signer: KeyDeckelSigner(),
          purse: CashuDeckelPurse(CashuWallet(store: MemoryProofStore(), mint: mint)),
          ledger: DeckelLedger(store: MemoryDeckelLedgerStore()),
          speech: _FakeSpeech(),
          voice: _FakeVoice(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Stammtisch Berlin'), findsOneWidget);
    expect(find.text('Platz nehmen'), findsOneWidget);

    await tester.tap(find.text('Platz nehmen'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Ralph');
    await tester.tap(find.text('Los'));
    await tester.pumpAndSettle();

    expect(backend.events, hasLength(1));
    expect(find.text('Du'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('Noch sitzt du allein. Lass die anderen diesen Code scannen.'), findsOneWidget);

    // Runde ohne zweiten Kopf: die Seite sagt, warum nicht.
    await tester.tap(find.text('Runde'));
    await tester.pumpAndSettle();
    expect(find.text('Zum Anschreiben braucht es mindestens zwei am Tisch.'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Der Tisch bleibt gemerkt, bis man ihn verlässt.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('deckel_current_id_v1'), 'a1b2c3d4e5f60718');
    await tester.tap(find.byTooltip('Tisch verlassen'));
    await tester.pumpAndSettle();
    expect(prefs.getString('deckel_current_id_v1'), isNull);
    expect(find.text('Neuer Deckel'), findsOneWidget);
  });
}
