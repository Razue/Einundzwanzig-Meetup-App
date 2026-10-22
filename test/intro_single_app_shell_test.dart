import 'package:einundzwanzig_meetup_app/l10n/app_localizations.dart';
import 'package:einundzwanzig_meetup_app/screens/app_shell.dart';
import 'package:einundzwanzig_meetup_app/screens/identity_setup_screen.dart';
import 'package:einundzwanzig_meetup_app/screens/intro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Die Einrichtung schliesst selbst mit pushAndRemoveUntil zur AppShell ab
  // und entfernt dabei das Intro. Das Intro darf danach nicht noch einmal
  // navigieren — sonst ersetzt es die frische AppShell durch eine zweite,
  // und zwei HomeScreens teilen sich die statischen Tour-Keys.
  testWidgets('intro does not navigate again after setup took over',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(402, 874);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(
      locale: Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: IntroScreen(),
    ));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ElevatedButton).first);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.byType(IdentitySetupScreen), findsOneWidget);

    // Einrichtung abgeschlossen: Profil gespeichert, Stapel abgeraeumt.
    // Statt der echten AppShell ein Platzhalter, damit sichtbar wird, ob
    // das Intro danach noch selbst eine AppShell oeffnet.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nickname', 'Satoshi');
    Navigator.of(tester.element(find.byType(IdentitySetupScreen)))
        .pushAndRemoveUntil(
      MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('home'))),
      (_) => false,
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(tester.takeException(), isNull);
    expect(find.text('home'), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(minutes: 1));
  });
}
