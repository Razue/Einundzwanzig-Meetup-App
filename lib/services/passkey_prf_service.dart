// ============================================
// PASSKEY / WebAuthn PRF — zweiter EasyAuth-Unlock
// ============================================
// Wie kickstr/assets/js/easy_auth/passkey.js: PRF-Secret wird als
// „Passwort“ für einen zweiten NIP-49-Wrap derselben Privkey genutzt.
// Ohne Backend — credential_id + wrap liegen in LocalKeyVault.
//
// Graceful degrade: DomainNotAssociated / fehlendes PRF → Exception,
// Aufrufer bleiben beim Passwort-Pfad.
// ============================================

import 'dart:convert';
import 'dart:math';

import 'package:convert/convert.dart';
import 'package:flutter/foundation.dart';
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/types.dart';

class PasskeyPrfException implements Exception {
  final String message;
  const PasskeyPrfException(this.message);

  @override
  String toString() => message;
}

class PasskeyPrfResult {
  final String credentialId;
  final String prfSecretHex;
  const PasskeyPrfResult({
    required this.credentialId,
    required this.prfSecretHex,
  });
}

class PasskeyPrfService {
  PasskeyPrfService._();

  static const _rpName = '21meetup';
  /// Native braucht Associated Domains / Asset Links für diese Domain.
  static const _nativeRpId = 'einundzwanzig.space';
  static final Uint8List _prfSaltBytes =
      Uint8List.fromList(utf8.encode('21meetup-easyauth-prf-v1'));

  static String get _prfSaltB64 => _b64urlNoPad(_prfSaltBytes);

  /// Web-Hosts, auf denen ein Passkey angelegt werden darf.
  ///
  /// WebAuthn bindet einen Passkey an die rpId, und im Browser ist das der
  /// Host. Auf einer GETEILTEN Domain wie `github.io` liegt dieser Namensraum
  /// bei ALLEN Projekten gemeinsam — ein Passkey für `razue.github.io` gehört
  /// dann nicht dieser App, sondern jeder Seite unter `github.io`. Genau
  /// deshalb prüft WebAuthn sonst eTLD+1, und genau da greift die Prüfung bei
  /// Nutzerprojekten nicht.
  ///
  /// Deshalb eine Liste statt „im Web aus": so bleibt es auf der PWA unter
  /// github.io aus, geht auf einer eigenen Domain aber ohne Codeänderung an —
  /// und der Grund steht dokumentiert, statt in einem `if (kIsWeb) return
  /// false` zu verschwinden.
  static const Set<String> allowedWebHosts = {
    'einundzwanzig.space',
    'localhost',
    '127.0.0.1',
  };

  /// Ist ein Passkey auf DIESER Umgebung überhaupt zulässig?
  static bool get isEnvironmentAllowed {
    if (!kIsWeb) return true; // Native: es entscheidet die Domain-Verknüpfung
    final host = Uri.base.host;
    if (host.isEmpty) return true; // Testumgebung ohne Host
    return allowedWebHosts.contains(host);
  }

  static String relyingPartyId() {
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host.isEmpty) return 'localhost';
      return host;
    }
    return _nativeRpId;
  }

  /// Grobe Plattform-Prüfung — sagt nichts über PRF-Unterstützung aus.
  ///
  /// Auf einer nicht freigegebenen Web-Domain antwortet sie bewusst mit false,
  /// damit die Oberfläche dort keinen Passkey anbietet.
  static Future<bool> isSupported() async {
    if (!isEnvironmentAllowed) return false;
    try {
      final auth = PasskeyAuthenticator();
      // ignore: deprecated_member_use
      return await auth.canAuthenticate();
    } catch (_) {
      return false;
    }
  }

  static Future<PasskeyPrfResult> register({
    required String userIdHex,
    required String userName,
  }) async {
    // Riegel auch hier, nicht nur in isSupported(): ein Passkey auf einer
    // geteilten Domain wäre eine dauerhafte Fehlanlage im Schlüsselbund des
    // Nutzers, und die bekommt er nur mühsam wieder weg.
    if (!isEnvironmentAllowed) {
      throw const PasskeyPrfException('RP_ID_NOT_ALLOWED');
    }
    final auth = PasskeyAuthenticator();
    final challenge = _randomChallengeB64();
    final userIdBytes = Uint8List.fromList(hex.decode(userIdHex));

    final response = await auth.register(
      RegisterRequestType(
        challenge: challenge,
        relyingParty: RelyingPartyType(name: _rpName, id: relyingPartyId()),
        user: UserType(
          displayName: userName,
          name: userName,
          id: _b64urlWithPad(userIdBytes),
        ),
        excludeCredentials: const [],
        authSelectionType: AuthenticatorSelectionType(
          authenticatorAttachment: 'platform',
          requireResidentKey: false,
          residentKey: 'preferred',
          userVerification: 'preferred',
        ),
        timeout: 60000,
        prf: _prfSaltB64,
      ),
    );

    var secret = _prfSecretHex(response.clientExtensionResults);
    if (secret == null) {
      // Viele Authenticatoren liefern PRF erst beim get().
      final unlocked = await unlock(credentialIds: [response.id]);
      return PasskeyPrfResult(
        credentialId: response.id,
        prfSecretHex: unlocked.prfSecretHex,
      );
    }

    return PasskeyPrfResult(
      credentialId: response.id,
      prfSecretHex: secret,
    );
  }

  static Future<PasskeyPrfResult> unlock({
    List<String> credentialIds = const [],
  }) async {
    final auth = PasskeyAuthenticator();
    final allow = credentialIds
        .map(
          (id) => CredentialType(
            type: 'public-key',
            id: id,
            transports: const [],
          ),
        )
        .toList();

    final response = await auth.authenticate(
      AuthenticateRequestType(
        relyingPartyId: relyingPartyId(),
        challenge: _randomChallengeB64(),
        mediation: MediationType.Optional,
        preferImmediatelyAvailableCredentials: false,
        userVerification: 'preferred',
        timeout: 60000,
        allowCredentials: allow.isEmpty ? null : allow,
        prf: _prfSaltB64,
      ),
    );

    final secret = _prfSecretHex(response.clientExtensionResults);
    if (secret == null) {
      throw const PasskeyPrfException('PRF_UNSUPPORTED');
    }

    return PasskeyPrfResult(
      credentialId: response.id,
      prfSecretHex: secret,
    );
  }

  static String? _prfSecretHex(Map<String?, Object?>? ext) {
    if (ext == null) return null;
    final prf = ext['prf'];
    if (prf is! Map) return null;
    final results = prf['results'];
    if (results is! Map) return null;
    final first = results['first'];
    if (first is! String || first.isEmpty) return null;
    try {
      final bytes = _b64urlDecode(first);
      if (bytes.isEmpty) return null;
      return hex.encode(bytes);
    } catch (_) {
      return null;
    }
  }

  static String _randomChallengeB64() {
    final bytes = Uint8List(32);
    final rnd = Random.secure();
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = rnd.nextInt(256);
    }
    return _b64urlNoPad(bytes);
  }

  static String _b64urlNoPad(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');

  static String _b64urlWithPad(List<int> bytes) => base64Url.encode(bytes);

  static List<int> _b64urlDecode(String input) {
    var s = input.replaceAll('-', '+').replaceAll('_', '/');
    final pad = (4 - s.length % 4) % 4;
    s = s.padRight(s.length + pad, '=');
    return base64.decode(s);
  }
}
