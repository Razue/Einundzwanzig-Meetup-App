// ============================================
// REGRESSIONSTEST H3 — gefälschte Zap-Quittungen
// ============================================
// Ein Angreifer stellt sich mit einem eigenen Schlüssel eine Kind-9735-
// Quittung aus. Vor dem Fix zählte sie als Lightning-Beweis, sobald das
// p-Tag passte.
// ============================================

import 'dart:convert';
import 'package:bech32/bech32.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nostr/nostr.dart';
import 'package:einundzwanzig_meetup_app/services/zap_receipt_validator.dart';

void main() {
  final attacker = Keychain.generate();
  final victim = Keychain.generate();
  final provider = Keychain.generate();

  List<int> toWords(List<int> bytes) {
    var acc = 0, bits = 0;
    final out = <int>[];
    for (final b in bytes) {
      acc = (acc << 8) | b;
      bits += 8;
      while (bits >= 5) {
        bits -= 5;
        out.add((acc >> bits) & 31);
      }
    }
    if (bits > 0) out.add((acc << (5 - bits)) & 31);
    return out;
  }

  /// Minimale bolt11-Rechnung mit Description-Hash [hashHex].
  String bolt11WithHash(String hashHex) {
    final hashBytes = List<int>.generate(
        32, (i) => int.parse(hashHex.substring(i * 2, i * 2 + 2), radix: 16));
    final hWords = toWords(hashBytes); // 52 Gruppen
    final data = <int>[
      ...List.filled(7, 1), // Timestamp
      23, (hWords.length >> 5) & 31, hWords.length & 31, ...hWords,
      ...List.filled(104, 0), // Signatur (Platzhalter)
    ];
    return Bech32Encoder().convert(Bech32('lnbc210n', data), 4096);
  }

  Map<String, dynamic> toMap(Event e) => {
        'id': e.id, 'pubkey': e.pubkey, 'created_at': e.createdAt,
        'kind': e.kind, 'tags': e.tags, 'content': e.content, 'sig': e.sig,
      };

  String zapRequest(Keychain sender, String recipient) => jsonEncode(toMap(
        Event.from(kind: 9734, tags: [['p', recipient], ['relays', 'wss://x']],
            content: '', privkey: sender.private),
      ));

  Map<String, dynamic> receipt({
    required Keychain issuer,
    required String recipient,
    required String description,
    String? bolt11,
  }) {
    final invoice = bolt11 ??
        bolt11WithHash(sha256.convert(utf8.encode(description)).toString());
    return toMap(Event.from(
      kind: 9735,
      tags: [['p', recipient], ['bolt11', invoice], ['description', description]],
      content: '',
      privkey: issuer.private,
    ));
  }

  test('Korrekt aufgebaute Quittung besteht die lokale Prüfung', () {
    final r = receipt(
      issuer: provider,
      recipient: victim.public,
      description: zapRequest(attacker, victim.public),
    );
    final check = ZapReceiptValidator.checkLocal(r);
    expect(check.ok, isTrue, reason: check.reason);
    expect(check.recipientPubkey, victim.public);
    expect(check.senderPubkey, attacker.public);
    expect(check.receiptPubkey, provider.public);
  });

  test('Angriff: bolt11 gehört nicht zum Zap-Request', () {
    final r = receipt(
      issuer: attacker,
      recipient: victim.public,
      description: zapRequest(attacker, victim.public),
      bolt11: bolt11WithHash('0' * 64),
    );
    final check = ZapReceiptValidator.checkLocal(r);
    expect(check.ok, isFalse);
    expect(check.reason, 'description_hash');
  });

  test('Angriff: Quittung ohne bolt11/description', () {
    final e = Event.from(kind: 9735, tags: [['p', victim.public]],
        content: '', privkey: attacker.private);
    expect(ZapReceiptValidator.checkLocal(toMap(e)).reason, 'tags');
  });

  test('Angriff: Zap-Request im description-Tag ist nicht signiert', () {
    final fakeReq = jsonDecode(zapRequest(attacker, victim.public)) as Map<String, dynamic>;
    fakeReq['sig'] = 'ff' * 64;
    final r = receipt(
      issuer: attacker,
      recipient: victim.public,
      description: jsonEncode(fakeReq),
    );
    expect(ZapReceiptValidator.checkLocal(r).reason, 'request_sig');
  });

  test('Angriff: Empfänger der Quittung weicht vom Zap-Request ab', () {
    final r = receipt(
      issuer: attacker,
      recipient: victim.public,
      description: zapRequest(attacker, attacker.public),
    );
    expect(ZapReceiptValidator.checkLocal(r).reason, 'recipient_mismatch');
  });

  test('Angriff: Quittung mit kaputter Signatur', () {
    final r = receipt(
      issuer: provider,
      recipient: victim.public,
      description: zapRequest(attacker, victim.public),
    )..['sig'] = 'aa' * 64;
    expect(ZapReceiptValidator.checkLocal(r).reason, 'receipt_sig');
  });

  test('descriptionHashOf liest das h-Feld aus einer bolt11', () {
    final h = 'ab' * 32;
    expect(ZapReceiptValidator.descriptionHashOf(bolt11WithHash(h)), h);
    expect(ZapReceiptValidator.descriptionHashOf('lnbc1kaputt'), isNull);
  });
}
