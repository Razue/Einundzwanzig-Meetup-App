import 'dart:convert';

import 'package:einundzwanzig_meetup_app/services/voice_wallet/cashu_token_amount.dart';
import 'package:flutter_test/flutter_test.dart';

String _token(Object json) => 'cashuA${base64Url.encode(utf8.encode(jsonEncode(json)))}';

void main() {
  test('cashuA summiert die Proofs in Satoshi', () {
    final token = _token({
      'token': [
        {
          'mint': 'https://mint.example',
          'proofs': [
            {'amount': 21, 'id': '00', 'secret': 'a', 'C': 'b'},
            {'amount': 2, 'id': '00', 'secret': 'c', 'C': 'd'},
          ],
        },
      ],
      'unit': 'sat',
    });

    final peek = peekCashuToken(token);
    expect(peek.isCashu, isTrue);
    expect(peek.sats, 23);
  });

  test('cashuB und andere Einheiten bleiben ohne Betrag', () {
    expect(peekCashuToken('cashuBabc').isCashu, isTrue);
    expect(peekCashuToken('cashuBabc').sats, isNull);

    final msat = _token({
      'token': [
        {
          'proofs': [
            {'amount': 1000},
          ],
        },
      ],
      'unit': 'msat',
    });
    expect(peekCashuToken(msat).isCashu, isTrue);
    expect(peekCashuToken(msat).sats, isNull);
  });

  test('normaler Text ist kein Token', () {
    expect(peekCashuToken('21v3:irgendwas').isCashu, isFalse);
  });
}
