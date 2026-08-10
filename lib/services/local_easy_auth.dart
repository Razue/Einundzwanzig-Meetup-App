// ============================================
// LOCAL EASYAUTH — Name + Passwort (+ optional Passkey)
// ============================================
// kickstr-Parität ohne Backend: Key client-seitig, NIP-49 Wrap lokal.
// ============================================

import 'package:nostr/nostr.dart';

import '../models/user.dart';
import 'local_key_vault.dart';
import 'nip49.dart';
import 'nostr_service.dart';
import 'passkey_prf_service.dart';
import 'secure_key_store.dart';
import 'signing_service.dart';

class LocalEasyAuthException implements Exception {
  final String message;
  const LocalEasyAuthException(this.message);

  @override
  String toString() => message;
}

class LocalEasyAuth {
  LocalEasyAuth._();

  /// Neu: Key erzeugen, Passwort-Wrap speichern, Nickname setzen.
  static Future<void> register({
    required String nickname,
    required String password,
  }) async {
    final name = nickname.trim();
    if (name.isEmpty || name == 'Anon') {
      throw const LocalEasyAuthException('Bitte einen Namen wählen.');
    }
    if (password.length < 8) {
      throw const LocalEasyAuthException(
          'Passwort muss mindestens 8 Zeichen haben.');
    }

    // Reihenfolge ist wichtig: Schluessel erst IM SPEICHER erzeugen, den Wrap
    // rechnen, und nur wenn beides geklappt hat etwas persistieren.
    //
    // Vorher wurde zuerst gespeichert und der Modus umgestellt, dann gerechnet.
    // scrypt braucht im Browser rund 38 Sekunden — geht die App in dieser Zeit
    // in den Hintergrund oder wirft der Schritt, blieb ein Schluessel im
    // local-Modus zurueck OHNE den Wrap, fuer den der Nutzer gerade ein
    // Passwort gesetzt hatte. Er haette also eine Sicherung zu haben geglaubt,
    // die es nicht gibt.
    final keychain = Keychain.generate();
    final wrap = await Nip49.encrypt(
      keychain.private,
      password,
      // NICHT `secure`: der Klartext liegt anschliessend dauerhaft im
      // Keystore daneben. Exportiert der Nutzer diesen Wrap spaeter, reiste
      // die Behauptung „hat das Geraet nie im Klartext verlassen" mit.
      keySecurity: KeySecurity.unknown,
    );

    // Neuer Key → alte Passkey-Wraps gehoeren zur VORHERIGEN Identitaet.
    // Ohne clear wuerde Resume/Passkey den alten Privkey wieder laden.
    await LocalKeyVault.clearPasskeyWrap();

    await NostrService.importPrivHex(keychain.private);
    await SigningService.useLocalMode();
    final npub = await SecureKeyStore.getNpub() ?? '';
    await LocalKeyVault.savePasswordWrap(wrap, npub: npub);

    final user = await UserProfile.load();
    user.nickname = name;
    user.nostrNpub = npub;
    user.hasNostrKey = true;
    user.isNostrVerified = true;
    await user.save();
  }

  /// Zweiter Unlock-Faktor: Passkey/PRF → eigener ncryptsec-Wrap.
  static Future<void> addPasskeyWrap({required String displayName}) async {
    final priv = await SecureKeyStore.getPrivHex();
    final npub = await SecureKeyStore.getNpub();
    if (priv == null || priv.isEmpty || npub == null || npub.isEmpty) {
      throw const LocalEasyAuthException('Kein lokaler Schlüssel vorhanden.');
    }

    final pubHex = Nip19.decodePubkey(npub);
    final created = await PasskeyPrfService.register(
      userIdHex: pubHex,
      userName: displayName.trim().isEmpty ? '21meetup' : displayName.trim(),
    );

    final wrap = await Nip49.encrypt(
      priv,
      created.prfSecretHex,
      keySecurity: KeySecurity.unknown,
      // Niedriges log_n ist hier RICHTIG, nicht nachlässig: das „Passwort" ist
      // ein 32-Byte-PRF-Geheimnis mit 256 Bit — da gibt es nichts zu erraten,
      // und scrypt schützt gegen Erraten. Gemessen im Browser: log_n 8 braucht
      // 214 ms, log_n 16 dagegen 38 SEKUNDEN. Mit 16 wäre genau der Pfad
      // unbenutzbar, der schnell sein soll.
      //
      // Dieser Wrap wird deshalb NIE exportiert — ein `ncryptsec` mit log_n 8
      // sieht für einen Prüfer schwach aus, auch wenn er es hier nicht ist.
      logN: 8,
    );
    await LocalKeyVault.savePasskeyWrap(
      ncryptsec: wrap,
      credentialId: created.credentialId,
    );
  }

  /// Entsperren mit Passwort (lädt Session in SecureKeyStore).
  static Future<void> unlockWithPassword(String password) async {
    final wrap = await LocalKeyVault.getPasswordWrap();
    if (wrap == null || wrap.isEmpty) {
      throw const LocalEasyAuthException('Kein gespeicherter Schlüssel.');
    }
    final priv = await Nip49.decrypt(wrap, password);
    await NostrService.importPrivHex(priv);
    await SigningService.useLocalMode();
  }

  /// Entsperren mit Passkey/PRF.
  static Future<void> unlockWithPasskey() async {
    final wrap = await LocalKeyVault.getPasskeyWrap();
    final credId = await LocalKeyVault.getPasskeyCredentialId();
    if (wrap == null || wrap.isEmpty || credId == null || credId.isEmpty) {
      throw const LocalEasyAuthException('Kein Passkey hinterlegt.');
    }
    final secret = await PasskeyPrfService.unlock(
      credentialIds: [credId],
    );
    final priv = await Nip49.decrypt(wrap, secret.prfSecretHex);
    await NostrService.importPrivHex(priv);
    await SigningService.useLocalMode();
  }
}
