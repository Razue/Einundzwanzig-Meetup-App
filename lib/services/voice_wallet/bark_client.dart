import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'bark_destination.dart';
import 'bark_local.dart';

enum BarkFail { unset, down, rejected, notEnough }

class BarkException implements Exception {
  final BarkFail fail;

  const BarkException(this.fail);
}

class BarkBalance {
  final int spendableSat;

  const BarkBalance(this.spendableSat);
}

class BarkInvoice {
  final String invoice;
  final int amountSat;

  const BarkInvoice(this.invoice, this.amountSat);
}

class BarkPayResult {
  final int balanceSat;

  /// Auszahlung auf eine Bitcoin-Adresse wartet auf die nächste Ark-Runde.
  final bool inRound;

  const BarkPayResult(this.balanceSat, {this.inRound = false});
}

class BarkSettings {
  final String baseUrl;
  final String token;

  const BarkSettings(this.baseUrl, this.token);

  bool get configured =>
      baseUrl.trim().isNotEmpty && token.trim().isNotEmpty;

  static const local = BarkSettings(barkLocalUrl, barkLocalToken);
}

/// Kleiner Client für das barkd auf diesem Rechner.
///
/// Bark ist die Wallet für Ark. Dieselbe Schnittstelle legt Lightning-
/// Rechnungen an, zahlt Rechnungen und schickt an Ark-Adressen.
class BarkClient {
  BarkClient({BarkSettings? settings, http.Client? httpClient})
    : _settings = settings ?? BarkSettings.local,
      _http = httpClient ?? http.Client();

  final BarkSettings _settings;
  final http.Client _http;

  Future<bool> connected() async {
    final body = await _send('GET', '/api/v1/wallet/connected');
    return body['connected'] == true;
  }

  Future<BarkBalance> balance() async {
    final body = await _send('GET', '/api/v1/wallet/balance');
    final spendable = body['spendable_sat'];
    if (spendable is! int) throw const BarkException(BarkFail.rejected);
    return BarkBalance(spendable);
  }

  Future<String> nextAddress() async {
    final body = await _send('POST', '/api/v1/wallet/addresses/next', {});
    final address = body['address'];
    if (address is! String || !address.startsWith('ark1')) {
      throw const BarkException(BarkFail.rejected);
    }
    return address;
  }

  Future<BarkInvoice> invoice(int amountSat) async {
    final body = await _send('POST', '/api/v1/lightning/receives/invoice', {
      'amount_sat': amountSat,
      'description': 'Sprach-Wallet',
    });
    final invoice = body['invoice'];
    if (invoice is! String || invoice.isEmpty) {
      throw const BarkException(BarkFail.rejected);
    }
    return BarkInvoice(invoice, amountSat);
  }

  /// `awaiting-payment`, `settled`, oder leer wenn barkd nichts dazu hat.
  Future<String> receiveState(String invoice) async {
    final body = await _send(
      'GET',
      '/api/v1/lightning/receives/${Uri.encodeComponent(invoice)}',
    );
    final state = body['state'];
    return state is String ? state : '';
  }

  Future<BarkPayResult> pay(PayDestination dest, {int? amountSat}) async {
    final amount = dest.amountSat ?? amountSat;
    if (dest.needsAmount && (amount == null || amount <= 0)) {
      throw const BarkException(BarkFail.rejected);
    }
    switch (dest.kind) {
      case PayKind.bolt11:
      case PayKind.lnurl:
      case PayKind.lightningAddress:
        await _send('POST', '/api/v1/lightning/pay', {
          'destination': dest.raw,
          if (dest.amountSat == null && amount != null) 'amount_sat': amount,
        });
      case PayKind.ark:
      case PayKind.bip321:
        await _send('POST', '/api/v1/wallet/send', {
          'destination': dest.raw,
          'amount_sat': ?amount,
        });
      case PayKind.onchain:
        await _send('POST', '/api/v1/wallet/send-onchain', {
          'destination': dest.raw,
          'amount_sat': amount,
        });
        final left = await balance();
        return BarkPayResult(left.spendableSat, inRound: true);
    }
    final left = await balance();
    return BarkPayResult(left.spendableSat);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    if (!_settings.configured) throw const BarkException(BarkFail.unset);
    final uri = Uri.parse('${_settings.baseUrl}$path');
    final headers = {
      'authorization': 'Bearer ${_settings.token}',
      'accept': 'application/json',
      if (body != null) 'content-type': 'application/json',
    };
    try {
      final response = await _call(method, uri, headers, body).timeout(
        Duration(seconds: method == 'GET' ? 20 : 70),
      );
      if (response.statusCode == 200) {
        if (response.body.isEmpty) return const {};
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) {
          return decoded.map((key, value) => MapEntry('$key', value));
        }
        throw const BarkException(BarkFail.rejected);
      }
      final detail = response.body.toLowerCase();
      if (detail.contains('insufficient') ||
          detail.contains('not enough') ||
          detail.contains("don't cover") ||
          detail.contains('do not cover')) {
        throw const BarkException(BarkFail.notEnough);
      }
      throw const BarkException(BarkFail.rejected);
    } on BarkException {
      rethrow;
    } on TimeoutException {
      throw const BarkException(BarkFail.down);
    } on SocketException {
      throw const BarkException(BarkFail.down);
    } on http.ClientException {
      throw const BarkException(BarkFail.down);
    } on FormatException {
      throw const BarkException(BarkFail.rejected);
    }
  }

  Future<http.Response> _call(
    String method,
    Uri uri,
    Map<String, String> headers,
    Map<String, dynamic>? body,
  ) {
    final encoded = body == null ? null : jsonEncode(body);
    switch (method) {
      case 'POST':
        return _http.post(uri, headers: headers, body: encoded);
      case 'GET':
        return _http.get(uri, headers: headers);
      default:
        throw const BarkException(BarkFail.rejected);
    }
  }
}
