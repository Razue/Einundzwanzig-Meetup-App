// ============================================
// LOCAL KEY VAULT — NIP-49 wraps on device
// ============================================
// Speichert die EasyAuth-Blobs neben dem Session-Key im Secure Storage:
//   - password_ncryptsec  (immer nach Neu-Registrierung)
//   - password_wrap_npub   (zu welchem Key der Wrap gehört)
//   - passkey_ncryptsec + credential_id  (optional, PRF-Wrap)
//
// Der Server von kickstr speichert dieselben opaken Blobs; hier liegen sie
// nur lokal. Cross-Device läuft über Backup / ncryptsec-Export.
// ============================================

import 'secure_key_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalKeyVault {
  LocalKeyVault._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const _passwordWrapKey = 'easyauth_password_ncryptsec';
  static const _passwordWrapNpubKey = 'easyauth_password_wrap_npub';
  static const _passkeyWrapKey = 'easyauth_passkey_ncryptsec';
  static const _passkeyCredKey = 'easyauth_passkey_credential_id';

  /// Speichert den Passwort-Wrap und bindet ihn an die npub des Schlüssels.
  /// Ohne npub-Bindung wäre ein alter Wrap nach Key-Wechsel nicht erkennbar.
  static Future<void> savePasswordWrap(
    String ncryptsec, {
    required String npub,
  }) async {
    await SecureKeyStore.ensureMigrated();
    await _storage.write(key: _passwordWrapKey, value: ncryptsec);
    await _storage.write(key: _passwordWrapNpubKey, value: npub);
  }

  static Future<String?> getPasswordWrap() async {
    await SecureKeyStore.ensureMigrated();
    return _storage.read(key: _passwordWrapKey);
  }

  static Future<String?> getPasswordWrapNpub() async {
    await SecureKeyStore.ensureMigrated();
    return _storage.read(key: _passwordWrapNpubKey);
  }

  /// true nur wenn Wrap vorhanden und an genau diese npub gebunden.
  /// Fehlt die Bindung (Altbestand), gilt das als Nicht-Treffer — sicherer
  /// als einen womöglich fremden Wrap herauszugeben.
  static Future<bool> passwordWrapMatchesNpub(String npub) async {
    final wrap = await getPasswordWrap();
    if (wrap == null || wrap.isEmpty) return false;
    final bound = await getPasswordWrapNpub();
    return bound != null && bound.isNotEmpty && bound == npub;
  }

  static Future<void> savePasskeyWrap({
    required String ncryptsec,
    required String credentialId,
  }) async {
    await SecureKeyStore.ensureMigrated();
    await _storage.write(key: _passkeyWrapKey, value: ncryptsec);
    await _storage.write(key: _passkeyCredKey, value: credentialId);
  }

  static Future<String?> getPasskeyWrap() async {
    await SecureKeyStore.ensureMigrated();
    return _storage.read(key: _passkeyWrapKey);
  }

  static Future<String?> getPasskeyCredentialId() async {
    await SecureKeyStore.ensureMigrated();
    return _storage.read(key: _passkeyCredKey);
  }

  static Future<bool> hasPasskeyWrap() async {
    final wrap = await getPasskeyWrap();
    final id = await getPasskeyCredentialId();
    return wrap != null &&
        wrap.isNotEmpty &&
        id != null &&
        id.isNotEmpty;
  }

  static Future<void> clearPasskeyWrap() async {
    await SecureKeyStore.ensureMigrated();
    await _storage.delete(key: _passkeyWrapKey);
    await _storage.delete(key: _passkeyCredKey);
  }

  static Future<void> clearAll() async {
    await SecureKeyStore.ensureMigrated();
    await _storage.delete(key: _passwordWrapKey);
    await _storage.delete(key: _passwordWrapNpubKey);
    await _storage.delete(key: _passkeyWrapKey);
    await _storage.delete(key: _passkeyCredKey);
  }
}
