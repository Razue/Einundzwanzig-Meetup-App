// Gesendete Zap-Belege haben im p-Tag den Empfänger. Eine Anfrage nur mit
// #p liefert sie nie. #P ist der Abrufweg (NIP-57); wer gezahlt hat, bleibt
// der Absender im signierten Zap-Request.

import 'package:flutter_test/flutter_test.dart';
import 'package:einundzwanzig_meetup_app/services/relay_socket.dart';
import 'package:einundzwanzig_meetup_app/services/zap_verification_service.dart';

void main() {
  const me = 'aa';
  const other = 'bb';
  const since = 1700000000;

  Map<String, dynamic> receipt(List<List<String>> tags) => {
        'kind': 9735,
        'pubkey': 'provider',
        'created_at': since + 10,
        'tags': tags,
      };

  test('Gesendete Zaps fragen #P, empfangene #p', () {
    final sent = ZapVerificationService.receiptFilter(
        pubkeyHex: me, since: since, sent: true);
    final received = ZapVerificationService.receiptFilter(
        pubkeyHex: me, since: since, sent: false);

    expect(sent['#P'], [me]);
    expect(sent.containsKey('#p'), isFalse);
    expect(received['#p'], [me]);
    expect(received.containsKey('#P'), isFalse);
  });

  test('Empfangsfrage behält Belege ohne P-Tag', () {
    final event = receipt([
      ['p', me],
    ]);
    final received = ZapVerificationService.receiptFilter(
        pubkeyHex: me, since: since, sent: false);
    final sent = ZapVerificationService.receiptFilter(
        pubkeyHex: me, since: since, sent: true);

    expect(RelaySocket.answersFilter(event, received), isTrue);
    expect(RelaySocket.answersFilter(event, sent), isFalse);
  });

  test('Gesendet-Filter trifft den Absender, nicht den Empfänger', () {
    final event = receipt([
      ['p', other],
      ['P', me],
    ]);
    final sent = ZapVerificationService.receiptFilter(
        pubkeyHex: me, since: since, sent: true);
    final received = ZapVerificationService.receiptFilter(
        pubkeyHex: me, since: since, sent: false);

    expect(RelaySocket.answersFilter(event, sent), isTrue);
    expect(RelaySocket.answersFilter(event, received), isFalse);
  });
}
