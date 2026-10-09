import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:einundzwanzig_meetup_app/services/admin_registry.dart';
import 'package:einundzwanzig_meetup_app/services/badge_security.dart';
import 'package:einundzwanzig_meetup_app/services/zap_receipt_validator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Organic-Name aus dem alten Claim ist kein Admin', () {
    expect(
      AdminEntry(npub: 'a', meetup: 'm', name: 'Organic (3 Badges)')
          .isLegacyOrganicClaim,
      isTrue,
    );
    expect(
      AdminEntry(npub: 'a', meetup: 'm', name: 'Ben').isLegacyOrganicClaim,
      isFalse,
    );
    expect(
      AdminEntry(npub: 'a', meetup: 'm', name: 'Organic admin')
          .isLegacyOrganicClaim,
      isFalse,
    );
  });

  test('getAdminList entfernt organische Alt-Claims aus dem Cache', () async {
    SharedPreferences.setMockInitialValues({
      'admin_registry_cache': jsonEncode([
        {
          'npub': 'npub1organic',
          'meetup': 'x',
          'name': 'Organic (4 Badges)',
          'added_at': 1,
        },
        {
          'npub': 'npub1real',
          'meetup': 'y',
          'name': 'Ben',
          'added_at': 2,
        },
      ]),
    });

    final list = await AdminRegistry.getAdminList();
    expect(list.map((e) => e.npub), ['npub1real']);

    final again = await AdminRegistry.getAdminList();
    expect(again, hasLength(1));
  });

  test('addAdmin lehnt den automatischen Organic-Namen ab', () async {
    SharedPreferences.setMockInitialValues({});
    expect(
      () => AdminRegistry.addAdmin(AdminEntry(
        npub: 'npub1organic',
        meetup: 'x',
        name: 'Organic (3 Badges)',
      )),
      throwsStateError,
    );
  });

  test('unsignierte la/lo sind keine gemessene Referenz', () {
    final coords = BadgeSecurity.signedCoordinates({
      'v': 2,
      't': 'B',
      'm': 'aschaffenburg-de',
      'la': 48.1,
      'lo': 10.2,
    });
    expect(coords.lat, 0);
    expect(coords.lng, 0);
  });

  test('Quittung vom eigenen Schlüssel zählt nicht als Provider', () async {
    final self = 'aa' * 32;
    final ok = await ZapReceiptValidator.isFromRecipientProvider(
      receiptPubkey: self,
      recipientPubkey: self,
    );
    expect(ok, isFalse);

    final asSender = await ZapReceiptValidator.isFromRecipientProvider(
      receiptPubkey: self,
      recipientPubkey: 'bb' * 32,
      senderPubkey: self,
    );
    expect(asSender, isFalse);
  });
}
