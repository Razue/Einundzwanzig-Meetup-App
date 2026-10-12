// Der Badge-Sync komprimiert die Hülle mit gzip. Hier nur die Runde.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:einundzwanzig_meetup_app/services/badge_sync_codec.dart';

void main() {
  test('gzip hin und zurück', () {
    const text = '{"v":1,"badges":[{"id":"x"}]}';
    final sealed = BadgeSyncCodec.deflate(text);
    expect(sealed, isNot(equals(utf8.encode(text))));
    expect(BadgeSyncCodec.inflate(sealed), text);
  });

  test('größerer Text bleibt lesbar', () {
    final text = List.filled(200, 'meetup').join(',');
    final sealed = BadgeSyncCodec.deflate(text);
    expect(sealed.length, lessThan(utf8.encode(text).length));
    expect(BadgeSyncCodec.inflate(sealed), text);
  });
}
