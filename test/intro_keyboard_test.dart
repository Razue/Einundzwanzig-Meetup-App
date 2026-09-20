import 'package:einundzwanzig_meetup_app/l10n/app_localizations.dart';
import 'package:einundzwanzig_meetup_app/screens/intro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('intro does not overflow when a dialog opens the keyboard',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(402, 874);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetViewInsets);

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
    expect(tester.takeException(), isNull);

    final context = tester.element(find.byType(IntroScreen));
    showDialog<void>(
      context: context,
      builder: (_) => const AlertDialog(
        title: Text('Backup entschlüsseln'),
        content: TextField(autofocus: true, obscureText: true),
      ),
    );
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 346);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(tester.getRect(find.byType(TextField)).bottom, lessThanOrEqualTo(528));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
