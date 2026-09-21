import 'package:einundzwanzig_meetup_app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final explicitBackground in [false, true]) {
    testWidgets(
        'snackbar text is readable with ${explicitBackground ? "explicit" : "themed"} dark background',
        (tester) async {
      final messenger = GlobalKey<ScaffoldMessengerState>();
      await tester.pumpWidget(MaterialApp(
        theme: appTheme,
        scaffoldMessengerKey: messenger,
        home: const Scaffold(),
      ));

      const message = 'Chatraum wird gesucht …';
      messenger.currentState!.showSnackBar(SnackBar(
        content: const Text(message),
        backgroundColor: explicitBackground ? cCard : null,
      ));
      await tester.pumpAndSettle();

      final textContext = tester.element(find.text(message));
      final foreground = DefaultTextStyle.of(textContext).style.color!;
      final background = explicitBackground
          ? cCard
          : Theme.of(textContext).snackBarTheme.backgroundColor!;
      final contrast = (foreground.computeLuminance() + 0.05) /
          (background.computeLuminance() + 0.05);

      expect(foreground, cText);
      expect(contrast, greaterThanOrEqualTo(4.5));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
