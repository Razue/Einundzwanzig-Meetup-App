// Erzeugt die FlutterSharedPreferences.xml für den Repro-Lauf: drei
// Klartext-Badges (Altformat "badges") und eine Wegwerf-Identität in den
// Einstellungen. 1.6.8 zieht beides beim ersten Start selbst in den
// sicheren Speicher um und legt dabei den Badge-Schlüssel an.

import 'dart:convert';
import 'dart:io';

import 'package:nostr/nostr.dart';

String _xml(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('"', '&quot;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');

void main(List<String> args) {
  final keys = Keychain.generate();
  final badges = [
    for (var i = 1; i <= 3; i++)
      jsonEncode({
        'id': 'repro-$i',
        'meetupName': 'Testmeetup $i',
        'date': DateTime.utc(2026, 9, i, 19).toIso8601String(),
        'iconPath': 'assets/badge_icon.png',
        'meetupEventId': 'repro-event-$i',
      }),
  ];
  // So legt shared_preferences_android eine String-Liste ab.
  final list = 'VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIGxpc3Qu!${jsonEncode(badges)}';
  File(args[0]).writeAsStringSync('''<?xml version='1.0' encoding='utf-8' standalone='yes' ?>
<map>
    <string name="flutter.badges">${_xml(list)}</string>
    <string name="flutter.nostr_nsec_key">${Nip19.encodePrivkey(keys.private)}</string>
    <string name="flutter.nostr_npub_key">${Nip19.encodePubkey(keys.public)}</string>
    <string name="flutter.nostr_priv_hex">${keys.private}</string>
</map>
''');
}
