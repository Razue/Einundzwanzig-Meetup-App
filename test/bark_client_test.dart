import 'dart:convert';

import 'package:einundzwanzig_meetup_app/services/voice_wallet/bark_client.dart';
import 'package:einundzwanzig_meetup_app/services/voice_wallet/bark_destination.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('Kontostand und Rechnung', () async {
    final httpClient = _Scripted([
      _json(200, {'spendable_sat': 11689}),
      _json(200, {'invoice': 'lnbc210n1p4txxxx'}),
    ]);
    final bark = BarkClient(
      settings: const BarkSettings('http://bark.test', 'token'),
      httpClient: httpClient,
    );

    expect((await bark.balance()).spendableSat, 11689);
    final invoice = await bark.invoice(21);
    expect(invoice.invoice, 'lnbc210n1p4txxxx');
    expect(httpClient.requests.last.url.path, '/api/v1/lightning/receives/invoice');
  });

  test('Rechnung mit Betrag wird ohne zweiten Betrag bezahlt', () async {
    final httpClient = _Scripted([
      _json(200, {'message': 'ok', 'payment_hash': 'abc'}),
      _json(200, {'spendable_sat': 100}),
    ]);
    final bark = BarkClient(
      settings: const BarkSettings('http://bark.test', 'token'),
      httpClient: httpClient,
    );
    final dest = parsePayDestination('lnbc210n1p4txxxx')!;
    final result = await bark.pay(dest);
    expect(result.balanceSat, 100);
    expect(result.inRound, isFalse);
    final body = jsonDecode(httpClient.bodies.first) as Map<String, dynamic>;
    expect(body.keys, ['destination']);
    expect(httpClient.requests.first.url.path, '/api/v1/lightning/pay');
  });

  test('Ark-Zahlung schickt den Betrag mit', () async {
    final httpClient = _Scripted([
      _json(200, {'message': 'ok'}),
      _json(200, {'spendable_sat': 50}),
    ]);
    final bark = BarkClient(
      settings: const BarkSettings('http://bark.test', 'token'),
      httpClient: httpClient,
    );
    await bark.pay(parsePayDestination('ark1qqexample')!, amountSat: 21);
    final body = jsonDecode(httpClient.bodies.first) as Map<String, dynamic>;
    expect(body['amount_sat'], 21);
    expect(httpClient.requests.first.url.path, '/api/v1/wallet/send');
  });

  test('Zu wenig Guthaben und fehlende Einrichtung', () async {
    final httpClient = _Scripted([
      http.Response('insufficient funds', 400),
    ]);
    final bark = BarkClient(
      settings: const BarkSettings('http://bark.test', 'token'),
      httpClient: httpClient,
    );
    await expectLater(
      bark.pay(parsePayDestination('lnbc1popen')!, amountSat: 5),
      throwsA(isA<BarkException>().having((e) => e.fail, 'fail', BarkFail.notEnough)),
    );
    final bare = BarkClient(
      settings: const BarkSettings('', ''),
      httpClient: httpClient,
    );
    await expectLater(
      bare.balance(),
      throwsA(isA<BarkException>().having((e) => e.fail, 'fail', BarkFail.unset)),
    );
  });
}

http.Response _json(int status, Object body) {
  return http.Response(jsonEncode(body), status, headers: {
    'content-type': 'application/json',
  });
}

class _Scripted extends http.BaseClient {
  _Scripted(this._left);

  final List<http.Response> _left;
  final List<http.Request> requests = [];
  final List<String> bodies = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request as http.Request);
    bodies.add((request as http.Request).body);
    final response = _left.removeAt(0);
    return http.StreamedResponse(
      Stream<List<int>>.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
    );
  }
}
