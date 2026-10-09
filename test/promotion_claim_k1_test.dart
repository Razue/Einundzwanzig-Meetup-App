// ============================================
// REGRESSIONSTEST K1 — Selbst-Promotion zum Organisator
// ============================================
// Stellt den Angriff aus dem Security-Audit nach:
//   - Ein einziger echter Beweis wird dreimal in den Claim kopiert
//   - Beweise ohne Teilnehmer-Bindung (claim_sig)
//   - Bindung mit einem FREMDEN Schlüssel
//   - Unsigniertes admin_pubkey-Feld zeigt auf bekannten Admin,
//     signiert hat aber jemand anderes
// Und den Positivfall: drei verschiedene Sessions, sauber gebunden.
// ============================================

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nostr/nostr.dart';
import 'package:einundzwanzig_meetup_app/services/badge_security.dart';
import 'package:einundzwanzig_meetup_app/services/promotion_claim_service.dart';

void main() {
  late Keychain admin;
  late Keychain claimer;
  late Keychain stranger;

  setUp(() {
    admin = Keychain.generate();
    claimer = Keychain.generate();
    stranger = Keychain.generate();
  });

  /// Kompakt-Badge, vom Organisator signiert. [createdAt] bestimmt die Session.
  Map<String, dynamic> organizerBadge(Keychain org, int createdAt,
      {String meetupId = 'aschaffenburg-de', int block = 875000}) {
    final content = {
      'v': 2, 't': 'B', 'm': meetupId, 'b': block, 'x': createdAt + 4 * 3600,
    };
    final contentJson = BadgeSecurity.canonicalJsonEncode(content);
    final tags = [['t', 'badge'], ['m', meetupId]];
    final event = Event.from(
      kind: 21000, tags: tags, content: contentJson,
      privkey: org.private, createdAt: createdAt,
    );
    return {...content, 'c': event.createdAt, 'p': event.pubkey, 's': event.sig};
  }

  /// Teilnehmer-Bindung (Kind 21002) wie BadgeClaimService.createClaim.
  Map<String, dynamic> bindBadge(Keychain who, Map<String, dynamic> badge,
      String sigId, int claimedAt) {
    final claimContent = {
      'action': 'claim_badge',
      'org_sig': badge['s'],
      'org_event_id': sigId,
      'org_pubkey': badge['p'],
      'block_height': badge['b'],
      'claimed_at': claimedAt,
    };
    final contentJson = BadgeSecurity.canonicalJsonEncode(claimContent);
    final tags = [
      ['t', 'badge_claim'],
      ['p', badge['p'] as String],
      ['block', badge['b'].toString()],
    ];
    final ev = Event.from(
      kind: 21002, tags: tags, content: contentJson,
      privkey: who.private, createdAt: claimedAt,
    );
    return {'claim_sig': ev.sig, 'claim_event_id': ev.id, 'claim_timestamp': claimedAt};
  }

  Map<String, dynamic> proofFor(Map<String, dynamic> badge,
      {Keychain? boundBy, String? adminPubkeyLabel}) {
    final sigId = sha256.convert(utf8.encode(badge['s'] as String)).toString();
    return {
      'meetup': badge['m'],
      'date': DateTime.now().toIso8601String(),
      'block': badge['b'],
      'sig': badge['s'],
      'sig_id': sigId,
      'admin_pubkey': adminPubkeyLabel ?? badge['p'],
      'sig_version': 2,
      'sig_content': jsonEncode(badge),
      if (boundBy != null)
        ...bindBadge(boundBy, badge, sigId, (badge['c'] as int) + 60),
    };
  }

  RawClaim claimWith(List<Map<String, dynamic>> proofs) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return RawClaim(
      pubkey: claimer.public,
      createdAt: now,
      content: jsonEncode({
        'type': 'admin_claim',
        'version': 1,
        'meetup': 'Aschaffenburg',
        'proofs': proofs,
      }),
    );
  }

  int day(int n) =>
      DateTime.now().millisecondsSinceEpoch ~/ 1000 - n * 86400;

  test('Positivfall: drei verschiedene Sessions, vom Claimer gebunden', () {
    final proofs = [
      proofFor(organizerBadge(admin, day(30)), boundBy: claimer),
      proofFor(organizerBadge(admin, day(20)), boundBy: claimer),
      proofFor(organizerBadge(admin, day(10)), boundBy: claimer),
    ];
    final result = PromotionClaimService.verifyClaim(claimWith(proofs), {admin.public});
    expect(result, isNotNull);
    expect(result!.verifiedBadgeCount, 3);
    expect(result.claimerPubkey, claimer.public);
  });

  test('Angriff: derselbe Beweis dreimal kopiert wird abgelehnt', () {
    final one = proofFor(organizerBadge(admin, day(10)), boundBy: claimer);
    final result = PromotionClaimService.verifyClaim(
        claimWith([one, Map.of(one), Map.of(one)]), {admin.public});
    expect(result, isNull);
  });

  test('Angriff: Beweise ohne Teilnehmer-Bindung zählen nicht', () {
    final proofs = [
      proofFor(organizerBadge(admin, day(30))),
      proofFor(organizerBadge(admin, day(20))),
      proofFor(organizerBadge(admin, day(10))),
    ];
    expect(PromotionClaimService.verifyClaim(claimWith(proofs), {admin.public}), isNull);
  });

  test('Angriff: Bindung mit fremdem Schlüssel zählt nicht', () {
    final proofs = [
      proofFor(organizerBadge(admin, day(30)), boundBy: stranger),
      proofFor(organizerBadge(admin, day(20)), boundBy: stranger),
      proofFor(organizerBadge(admin, day(10)), boundBy: stranger),
    ];
    expect(PromotionClaimService.verifyClaim(claimWith(proofs), {admin.public}), isNull);
  });

  test('Angriff: admin_pubkey zeigt auf bekannten Admin, signiert hat ein Fremder', () {
    final proofs = [
      proofFor(organizerBadge(stranger, day(30)), boundBy: claimer, adminPubkeyLabel: admin.public),
      proofFor(organizerBadge(stranger, day(20)), boundBy: claimer, adminPubkeyLabel: admin.public),
      proofFor(organizerBadge(stranger, day(10)), boundBy: claimer, adminPubkeyLabel: admin.public),
    ];
    expect(PromotionClaimService.verifyClaim(claimWith(proofs), {admin.public}), isNull);
  });

  test('Drei Badges aus EINER Session reichen nicht', () {
    final t = day(10);
    final proofs = [
      proofFor(organizerBadge(admin, t, block: 1), boundBy: claimer),
      proofFor(organizerBadge(admin, t + 600, block: 2), boundBy: claimer),
      proofFor(organizerBadge(admin, t + 1200, block: 3), boundBy: claimer),
    ];
    expect(PromotionClaimService.verifyClaim(claimWith(proofs), {admin.public}), isNull);
  });
}
