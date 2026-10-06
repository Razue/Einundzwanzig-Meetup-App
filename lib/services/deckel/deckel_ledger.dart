// Jede Zahlung geht höchstens einmal raus.
//
// Eine Zahlung des Kassensturzes hat einen festen Schlüssel (once). Beim
// ersten "Zahlen" holt das Buch einen Token aus der Wallet und merkt ihn
// sich unter diesem Schlüssel. Jedes weitere "Zahlen" — zweiter Tipp,
// Neustart der App, Wechsel der Seite — zeigt denselben Token wieder und
// nimmt kein zweites Mal Geld aus der Wallet. Denselben Token kann der
// Empfänger nur einmal einlösen.
//
// Der Token liegt im Schlüsselbund: Bis der Empfänger ihn eingelöst hat,
// ist er das Geld.
//
// Eine Lücke bleibt: Stürzt die App ab, nachdem die Wallet den Token
// erzeugt hat und bevor er hier gespeichert ist, ist dieser Betrag weg.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../voice_wallet/cashu_token.dart';
import '../voice_wallet/cashu_wallet.dart';

/// Woraus bezahlt und wohin eingelöst wird.
abstract class DeckelPurse {
  Future<int> balance();

  /// Ein Token über genau [sats].
  Future<String> token(int sats);

  /// Betrag eines Tokens, ohne ihn einzulösen. Null, wenn es keiner ist.
  int? amountOf(String token);

  /// Löst ein und gibt zurück, wie viel angekommen ist.
  Future<int> redeem(String token);
}

/// Die Sprach-Wallet der App.
class CashuDeckelPurse implements DeckelPurse {
  CashuDeckelPurse([CashuWallet? wallet]) : _wallet = wallet ?? CashuWallet();

  final CashuWallet _wallet;

  @override
  Future<int> balance() => _wallet.balance();

  @override
  Future<String> token(int sats) async => (await _wallet.send(sats)).token;

  @override
  int? amountOf(String token) {
    try {
      final sat = parseCashuTokens(token).where((t) => t.unit.toLowerCase() == 'sat');
      if (sat.isEmpty) return null;
      return sat.fold<int>(0, (sum, t) => sum + t.proofs.fold<int>(0, (s, p) => s + p.amount));
    } on FormatException {
      return null;
    }
  }

  @override
  Future<int> redeem(String token) async => (await _wallet.receive(token)).received;
}

abstract class DeckelLedgerStore {
  Future<Map<String, String>> load();
  Future<void> save(Map<String, String> tokens);
}

class SecureDeckelLedgerStore implements DeckelLedgerStore {
  SecureDeckelLedgerStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  static const _key = 'deckel_ledger_v1';
  final FlutterSecureStorage _storage;

  @override
  Future<Map<String, String>> load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return {};
    final json = jsonDecode(raw);
    if (json is! Map) return {};
    return {
      for (final entry in json.entries)
        if (entry.key is String && entry.value is String) entry.key as String: entry.value as String,
    };
  }

  @override
  Future<void> save(Map<String, String> tokens) => _storage.write(key: _key, value: jsonEncode(tokens));
}

class MemoryDeckelLedgerStore implements DeckelLedgerStore {
  Map<String, String> tokens = {};

  @override
  Future<Map<String, String>> load() async => Map.of(tokens);

  @override
  Future<void> save(Map<String, String> tokens) async {
    this.tokens = Map.of(tokens);
  }
}

class DeckelLedger {
  DeckelLedger({DeckelLedgerStore? store}) : _store = store ?? SecureDeckelLedgerStore();

  final DeckelLedgerStore _store;
  Future<void> _tail = Future.value();

  /// Der Token dieser Zahlung, falls sie schon einmal ausgelöst wurde.
  Future<String?> tokenFor(String once) => _locked(() async => (await _store.load())[once]);

  /// Der Token dieser Zahlung. Nur beim ersten Aufruf verlässt Geld die Wallet.
  Future<String> pay({
    required String once,
    required int sats,
    required DeckelPurse purse,
  }) {
    return _locked(() async {
      final tokens = await _store.load();
      final known = tokens[once];
      if (known != null) return known;
      final token = await purse.token(sats);
      tokens[once] = token;
      await _store.save(tokens);
      return token;
    });
  }

  // Zwei Tipps kurz hintereinander dürfen nicht beide die Wallet erreichen.
  Future<T> _locked<T>(Future<T> Function() run) {
    final previous = _tail;
    final gate = Completer<void>();
    _tail = gate.future;
    return previous.then((_) => run()).whenComplete(gate.complete);
  }
}
