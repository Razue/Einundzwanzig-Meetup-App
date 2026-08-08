import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_logger.dart';
import 'mempool_config.dart';

/// Fehler mit Kontext — damit im Diagnose-Log steht, WARUM eine Quelle
/// gescheitert ist (Statuscode + Anfang der Antwort). Genau das hat bisher
/// gefehlt: alle Fehler wurden mit `catch (_)` stumm verschluckt.
class MempoolHttpException implements Exception {
  final String path;
  final int statusCode;
  final String snippet;

  MempoolHttpException(this.path, this.statusCode, String body)
      : snippet = _snip(body);

  static String _snip(String body) {
    final flat = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    return flat.length > 120 ? '${flat.substring(0, 120)}…' : flat;
  }

  /// Typische Sperr-Antworten (Cloudflare / Rate-Limit / WAF).
  bool get looksBlocked =>
      statusCode == 403 ||
      statusCode == 429 ||
      statusCode == 503 ||
      snippet.toLowerCase().contains('cloudflare') ||
      snippet.toLowerCase().contains('<!doctype html');

  @override
  String toString() => 'HTTP $statusCode bei $path — $snippet';
}

/// Gebündelte Kennzahlen fürs Bitcoin-Dashboard.
class BitcoinDashboardData {
  final int blockHeight;
  final int feeLow;      // sat/vB (economy / low)
  final int feeMedium;   // sat/vB (half hour / medium)
  final int feeHigh;     // sat/vB (fastest / high)
  final double priceEur; // BTC/EUR
  final double priceUsd; // BTC/USD (für Moscow Time)
  final int supply;      // aktuell existierende BTC (ganze Coins, berechnet)
  final double hashrateEhs; // EH/s
  final double difficultyChangePct; // z.B. -3.7
  final int difficultyRemainingBlocks; // verbleibende Blöcke bis Anpassung
  final double lnCapacityBtc;  // Lightning-Kapazität in BTC
  final int lnNodeCount;       // Anzahl Lightning-Nodes
  final int lnChannelCount;    // Anzahl Lightning-Kanäle
  final DateTime updatedAt;

  /// Wie viele der [sourcesTotal] Quellen in DIESEM Durchlauf geklappt haben.
  /// 0 = komplett offline/geblockt. Das Dashboard darf dann nicht mehr
  /// fröhlich "grün" anzeigen.
  final int sourcesOk;
  final int sourcesTotal;

  /// Kurze, für Menschen lesbare Fehlerursache (letzter Fehler), z.B.
  /// "HTTP 403" — leer, wenn alles geklappt hat.
  final String lastError;

  /// true, wenn der Server die Anfragen aktiv abgewiesen hat (Cloudflare/
  /// Rate-Limit). Typischer Fall bei Tor-Exit-IPs.
  final bool blocked;

  const BitcoinDashboardData({
    required this.blockHeight,
    required this.feeLow,
    required this.feeMedium,
    required this.feeHigh,
    required this.priceEur,
    required this.priceUsd,
    required this.supply,
    required this.hashrateEhs,
    required this.difficultyChangePct,
    required this.difficultyRemainingBlocks,
    required this.lnCapacityBtc,
    required this.lnNodeCount,
    required this.lnChannelCount,
    required this.updatedAt,
    this.sourcesOk = 0,
    this.sourcesTotal = 6,
    this.lastError = '',
    this.blocked = false,
  });

  /// Alle Quellen haben geliefert.
  bool get isLive => sourcesOk == sourcesTotal;

  /// Gar nichts geliefert — echter Offline-/Blockier-Zustand.
  bool get isDead => sourcesOk == 0;

  /// Moscow Time = Sats pro 1 USD, gelesen wie eine Uhrzeit.
  /// Beispiel: 1827 Sats/USD -> "18:27".
  String get moscowTime {
    if (priceUsd <= 0) return '--:--';
    final satsPerDollar = (100000000 / priceUsd).round();
    final s = satsPerDollar.toString().padLeft(4, '0');
    final head = s.substring(0, s.length - 2);
    final tail = s.substring(s.length - 2);
    return '$head:$tail';
  }
}

class MempoolService {
  static const String _tag = 'Mempool';

  /// Eigener User-Agent. Der Default von Dart ist `Dart/3.x (dart:io)` —
  /// ein deutliches Bot-Signal, das WAFs (Cloudflare) gern blocken.
  static const String _userAgent = '21Meetup/1.3 (Einundzwanzig Meetup App)';

  // =============================================
  // CORS: WARUM IM BROWSER ANDERE HEADER GELTEN
  // =============================================
  //
  // Im Web schlug JEDE mempool-Anfrage fehl:
  //
  //   Access to fetch at 'https://mempool.space/api/blocks/tip/height'
  //   has been blocked by CORS policy: Response to preflight request
  //   doesn't pass access control check: It does not have HTTP ok status.
  //
  // Ursache ist `Cache-Control`. Der Header steht NICHT auf der
  // CORS-Safelist, erzwingt damit einen Preflight — und mempool.space
  // antwortet auf OPTIONS mit 404. Auf einfache GETs antwortet es dagegen
  // mit `access-control-allow-origin: *`.
  //
  // Im Browser gemessen (flutter test --platform chrome):
  //
  //   ohne Header        HTTP 200
  //   nur Accept         HTTP 200
  //   nur User-Agent     HTTP 200   (Browser verwirft ihn stillschweigend)
  //   nur Cache-Control  ClientException   <- Ursache
  //
  // `User-Agent` ist im Browser ein verbotener Header: er wird ohnehin
  // verworfen, das WAF-Argument oben greift dort also nicht. Weglassen
  // vermeidet nur die Konsolenwarnung.
  //
  // Das Ziel des Headers — kein veralteter Wert aus einem CDN — wird im Web
  // stattdessen mit einem Cache-Buster im Query-String erreicht. Der loest
  // keinen Preflight aus; verifiziert mit HTTP 200.
  // =============================================

  /// Header, die nur ausserhalb des Browsers gesetzt werden dürfen.
  @visibleForTesting
  static Map<String, String> get platformHeaders =>
      kIsWeb ? const {} : const {'User-Agent': _userAgent};

  /// `Cache-Control` nur nativ — im Web bricht er CORS.
  @visibleForTesting
  static Map<String, String> get noCacheHeaders =>
      kIsWeb ? const {} : const {'Cache-Control': 'no-cache'};

  /// Im Web einen Cache-Buster anhängen, nativ die URL unverändert lassen.
  ///
  /// Bewusst ein unauffälliger Parametername und ein Zeitstempel in Sekunden:
  /// feiner aufgelöst würde jeder Aufruf am CDN vorbeigehen, gröber käme ein
  /// veralteter Wert durch. Die Blockhöhe ändert sich alle ~10 Minuten.
  @visibleForTesting
  static Uri cacheBusted(Uri uri) => kIsWeb
      ? uri.replace(queryParameters: {
          ...uri.queryParameters,
          '_': '${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
        })
      : uri;

  /// EIN geteilter Client statt sechs Einzel-Clients.
  /// Die Top-Level-Funktion `http.get()` legt pro Aufruf einen neuen Client an
  /// und schließt ihn wieder — über Tor bedeutet das sechs frische Circuits
  /// und sechs TLS-Handshakes pro Refresh. Mit Keep-alive läuft alles über
  /// eine Verbindung.
  ///
  /// ABER: Keep-alive-Sockets überleben keinen Netzwechsel. Schaltet der
  /// Nutzer Orbot AN oder AUS, während die App läuft, zeigen die offenen
  /// Verbindungen ins Leere — die nächsten Requests würden in den Timeout
  /// laufen. Deshalb ist der Client NICHT final, sondern wird verworfen,
  /// sobald sich der Host ändert oder ein kompletter Fehlschlag auftritt.
  static http.Client _client = http.Client();

  /// Host, für den der aktuelle Client aufgebaut wurde.
  static String _clientHost = '';

  /// Verbindungspool wegwerfen und frisch aufbauen.
  /// Aufrufen bei: Host-Wechsel, Totalausfall, Orbot-Umschaltung.
  static void resetClient() {
    try {
      _client.close();
    } catch (_) {
      // Schon geschlossen — egal.
    }
    _client = http.Client();
    _clientHost = MempoolConfig.host;
    AppLogger.diag(_tag, 'HTTP-Client neu aufgebaut für $_clientHost');
  }

  /// Blockhöhe wird auch im Meetup-Ablauf geholt (Rolling QR, Co-Attendance)
  /// — dort MIT Retry. Mit dem vollen Onion-Timeout (45 s) käme man auf über
  /// 90 s Wartezeit beim Scannen. Für diesen Pfad wird das Zeitlimit gekappt.
  static const Duration _blockHeightMaxTimeout = Duration(seconds: 20);

  // =============================================
  // MONOTONE BLOCKHÖHE (v1.3.1)
  // =============================================
  // Die Blockhöhe ist die EINZIGE Kennzahl mit einer harten Invariante:
  // sie kann nur steigen. Genau die nutzen wir, um drei Fehler auf einmal
  // zu erschlagen:
  //
  // 1. RENNEN ZWISCHEN DEN AUFRUFERN. Drei Stellen holen unabhängig Daten
  //    (Widget-Rädchen im Hintergrund-Isolate, Home-Kachel, Dashboard —
  //    beide mit 60-s-Timer). Jeder las beim Start den alten Stand und
  //    schrieb beim Ende. Der LANGSAMSTE gewann. Holte das Rädchen die
  //    frische Höhe und der Vordergrund-Timer scheiterte kurz danach an
  //    seinem eigenen Fetch, überschrieb er das Widget wieder mit dem alten
  //    Wert -> "kurz nach dem Aktualisieren steht wieder der alte Stand da".
  //
  // 2. HINTERGRUND-ISOLATE HAT KEIN GEDÄCHTNIS. `lastDashboard` ist ein
  //    static — im frischen Isolate des Refresh-Rädchens also IMMER null.
  //    Scheiterte dort die Blockhöhe, während andere Quellen lieferten,
  //    schrieb es eine 0 ("––") ins Widget.
  //
  // 3. DER ALTE 0-GUARD MASKIERTE DEN FEHLER. `height0 > 0 ? height0 : prev`
  //    nahm bei Fehlschlag stillschweigend den alten Wert — und schrieb ihn
  //    mit frischem "Stand HH:MM" ins Widget. Es SAH aus wie aktualisiert.
  //
  // Lösung: die zuletzt bekannte Höhe liegt in SharedPreferences (nicht nur
  // im RAM eines Isolates) und darf NIE zurückgehen. Ein Fehlschlag oder eine
  // veraltete CDN-Antwort kann einen neueren Wert damit nicht mehr kippen.
  static const String _kLastHeight = 'mempool_last_height';
  static int _lastKnownHeight = 0;

  /// Letzte bekannte Höhe lesen — MIT `reload()`, sonst sieht der Vordergrund
  /// nicht, was das Hintergrund-Isolate (Refresh-Rädchen) geschrieben hat:
  /// SharedPreferences hält pro Isolate einen eigenen Cache.
  static Future<int> _loadLastHeight() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.reload();
      final v = p.getInt(_kLastHeight) ?? 0;
      if (v > _lastKnownHeight) _lastKnownHeight = v;
    } catch (_) {
      // Prefs nicht lesbar -> mit dem Wert aus dem RAM weiterarbeiten.
    }
    return _lastKnownHeight;
  }

  static Future<void> _saveLastHeight(int h) async {
    if (h <= _lastKnownHeight) return; // niemals rückwärts
    _lastKnownHeight = h;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt(_kLastHeight, h);
    } catch (_) {
      // Nicht schlimm — gilt zumindest für diese Sitzung.
    }
  }

  // =============================================
  // SINGLE-FLIGHT
  // =============================================
  // Läuft schon ein Abruf, bekommen weitere Aufrufer DENSELBEN Future statt
  // eine zweite Runde von sechs Requests. Verhindert das Rennen an der Wurzel
  // und halbiert nebenbei die Last auf mempool.space (Rate-Limits!).
  static Future<BitcoinDashboardData>? _inFlight;

  /// Letzter erfolgreich geladener Datensatz — wird angezeigt, während neu
  /// geladen wird oder falls eine Quelle mal ausfällt (keine leere Kachel).
  static BitcoinDashboardData? lastDashboard;

  // Fehlerbild des letzten Durchlaufs (für Dashboard-Hinweis + Log).
  static String _lastError = '';
  static bool _lastBlocked = false;

  // =============================================
  // ZENTRALER GET
  // Prüft den Statuscode WIRKLICH und wirft mit Kontext.
  // =============================================
  static Future<http.Response> _get(String path, {Duration? maxTimeout}) async {
    await MempoolConfig.ensureLoaded();

    // Host gewechselt (Einstellungen geändert)? Dann darf der alte
    // Verbindungspool nicht weiterverwendet werden.
    if (_clientHost != MempoolConfig.host) resetClient();

    // Im Browser wird der Cache anders umgangen als per Header — siehe
    // noCacheHeaders und cacheBusted. Sonst blockt CORS die Anfrage ganz.
    final uri = cacheBusted(Uri.parse('${MempoolConfig.apiBase}$path'));

    var timeout = MempoolConfig.timeout;
    if (maxTimeout != null && maxTimeout < timeout) timeout = maxTimeout;

    final r = await _client.get(uri, headers: {
      ...platformHeaders,
      'Accept': 'application/json, text/plain, */*',
      ...noCacheHeaders,
    }).timeout(timeout);

    if (r.statusCode != 200) {
      throw MempoolHttpException(path, r.statusCode, r.body);
    }
    return r;
  }

  /// Einheitliches Logging aller Fehlschläge — das ist der Kern des Fixes.
  /// Vorher: `catch (_)`, also absolute Stille im Diagnose-Log.
  static String? _lastNetSig;
  static DateTime? _lastNetSigAt;

  static void _logFailure(String source, Object e) {
    if (e is MempoolHttpException) {
      _lastError = 'HTTP ${e.statusCode}';
      if (e.looksBlocked) _lastBlocked = true;
      AppLogger.diag(_tag,
          '$source FEHLGESCHLAGEN — HTTP ${e.statusCode} @ ${MempoolConfig.host}${e.path} · Antwort: ${e.snippet}');
    } else {
      final type = e.runtimeType.toString();
      _lastError = type;
      // ENTRAUSCHEN (Feldtest): Bei Funkloch/Offline scheitern ALLE SECHS
      // Quellen gleichzeitig mit demselben Netzwerkfehler — das hat das
      // Diagnose-Log geflutet und echte App-Meldungen unauffindbar gemacht.
      // Dieselbe Stoerung wird deshalb nur EINMAL pro Abrufzyklus notiert;
      // die Gesamtmeldung "ALLE Quellen fehlgeschlagen" bleibt erhalten.
      final sig = '$type@${MempoolConfig.host}';
      final now = DateTime.now();
      if (_lastNetSig == sig &&
          _lastNetSigAt != null &&
          now.difference(_lastNetSigAt!) < const Duration(seconds: 30)) {
        return;
      }
      _lastNetSig = sig;
      _lastNetSigAt = now;
      AppLogger.diag(_tag,
          '$source FEHLGESCHLAGEN — $type @ ${MempoolConfig.host} · $e '
          '(weitere gleichartige Fehler dieses Abrufs werden unterdrueckt)');
    }
  }

  // Holt die aktuelle Blockhöhe (Tip Height).
  // Vertrag bleibt: 0 bei Fehler (rolling_qr_service, coattendance_service,
  // meetup_verification verlassen sich darauf). Aber jetzt MIT Log-Eintrag.
  static Future<int> getBlockHeight() async {
    try {
      final r = await _get('/blocks/tip/height',
          maxTimeout: _blockHeightMaxTimeout);
      final h = int.tryParse(r.body.trim());
      if (h == null || h <= 0) {
        AppLogger.diag(_tag,
            'Blockhöhe: unlesbare Antwort (kein Integer): "${r.body.length > 60 ? '${r.body.substring(0, 60)}…' : r.body}"');
        return 0;
      }
      return h;
    } catch (e) {
      _logFailure('Blockhöhe', e);
      return 0; // Offline oder Fehler
    }
  }

  /// Vom mempool.space-Preis-Endpoint unterstützte Fiat-Währungen.
  static const List<String> supportedCurrencies = [
    'EUR', 'USD', 'GBP', 'CHF', 'CAD', 'AUD', 'JPY',
  ];

  /// Holt die aktuellen BTC-Preise in allen unterstützten Währungen.
  /// Gibt eine Map zurück, z.B. {'EUR': 95000.0, 'USD': 103000.0, ...}.
  /// Leere Map bei Fehler/offline.
  static Future<Map<String, double>> getPrices() async {
    try {
      final r = await _get('/v1/prices');
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      final result = <String, double>{};
      for (final cur in supportedCurrencies) {
        final v = data[cur];
        if (v is num) result[cur] = v.toDouble();
      }
      return result;
    } catch (e) {
      _logFailure('Preise', e);
      return {};
    }
  }

  /// Einmaliger Verbindungstest gegen einen BELIEBIGEN Host — für den
  /// "Verbindung testen"-Knopf in den Einstellungen. Ändert die Config nicht.
  /// Gibt die Blockhöhe zurück, oder wirft mit sprechendem Fehler.
  static Future<int> testHost(String rawHost) async {
    final host = MempoolConfig.normalize(rawHost);
    final isOnion = host.contains('.onion');
    final uri = Uri.parse('$host/api/blocks/tip/height');

    // BEWUSST ein eigener Wegwerf-Client: Der Test soll die Wahrheit über
    // JETZT sagen. Ein alter Verbindungspool (z.B. von vor dem Orbot-Start)
    // könnte das Ergebnis verfälschen.
    final client = http.Client();
    try {
      final r = await client.get(cacheBusted(uri), headers: {
        ...platformHeaders,
        'Accept': 'text/plain, */*',
      }).timeout(Duration(seconds: isOnion ? 45 : 20));

      if (r.statusCode != 200) {
        throw MempoolHttpException('/blocks/tip/height', r.statusCode, r.body);
      }
      final h = int.tryParse(r.body.trim());
      if (h == null || h <= 0) {
        throw MempoolHttpException(
            '/blocks/tip/height', 200, 'Keine Zahl: ${r.body}');
      }
      AppLogger.diag(_tag, 'Verbindungstest OK: $host -> Block $h');
      return h;
    } finally {
      client.close();
    }
  }

  /// Errechnet die zum Block-Zeitpunkt existierende BTC-Menge (ganze Coins)
  /// aus dem deterministischen Ausgabeschema (50 BTC, Halbierung alle
  /// 210.000 Blöcke). Braucht keine API.
  static int _circulatingSupply(int height) {
    var reward = 50.0;
    var supply = 0.0;
    var h = height;
    while (h > 0 && reward >= 0.00000001) {
      final blocksInEra = h > 210000 ? 210000 : h;
      supply += blocksInEra * reward;
      h -= blocksInEra;
      reward /= 2;
    }
    return supply.round();
  }

  /// Holt alle Dashboard-Kennzahlen parallel von der konfigurierten Instanz.
  /// Einzelne fehlgeschlagene Quellen fallen auf den letzten bekannten Wert
  /// (bzw. 0) zurück, statt die ganze Kachel leer zu lassen — ABER es wird
  /// jetzt mitgezählt, wie viele Quellen wirklich geliefert haben, und jeder
  /// Fehlschlag landet im Diagnose-Log.
  static Future<BitcoinDashboardData> getDashboardData() {
    final running = _inFlight;
    if (running != null) return running; // Abruf läuft schon -> mitbenutzen

    final f = _fetchDashboard();
    _inFlight = f;
    f.whenComplete(() {
      if (identical(_inFlight, f)) _inFlight = null;
    });
    return f;
  }

  static Future<BitcoinDashboardData> _fetchDashboard() async {
    await MempoolConfig.ensureLoaded();
    final prev = lastDashboard;

    _lastError = '';
    _lastBlocked = false;
    var ok = 0;

    // safe() zählt Erfolge und loggt Fehler — kein stummes catch(_) mehr.
    Future<T> safe<T>(String source, Future<T> Function() f, T fallback) async {
      try {
        final v = await f();
        ok++;
        return v;
      } catch (e) {
        _logFailure(source, e);
        return fallback;
      }
    }

    final results = await Future.wait([
      // getBlockHeight() fängt intern selbst ab und gibt 0 zurück; deshalb
      // hier keine Exception -> Erfolg separat an der 0 erkennen.
      getBlockHeight(),
      safe('Fees', () async {
        final r = await _get('/v1/fees/recommended');
        final d = jsonDecode(r.body) as Map<String, dynamic>;
        return [
          (d['economyFee'] as num?)?.toInt() ?? (d['minimumFee'] as num?)?.toInt() ?? 0,
          (d['halfHourFee'] as num?)?.toInt() ?? 0,
          (d['fastestFee'] as num?)?.toInt() ?? 0,
        ];
      }, <int>[-1, -1, -1]),
      // getPrices() fängt (wie getBlockHeight) intern ab und gibt eine leere
      // Map zurück, statt zu werfen -> Erfolg unten an der Leere erkennen,
      // NICHT über safe(), sonst würde ein Fehlschlag als Erfolg gezählt.
      getPrices(),
      safe('Hashrate', () async {
        final r = await _get('/v1/mining/hashrate/3d');
        final d = jsonDecode(r.body) as Map<String, dynamic>;
        final hr = (d['currentHashrate'] as num?)?.toDouble() ?? 0;
        return hr / 1e18; // H/s -> EH/s
      }, -1.0),
      safe('Difficulty', () async {
        final r = await _get('/v1/difficulty-adjustment');
        final d = jsonDecode(r.body) as Map<String, dynamic>;
        return [
          (d['difficultyChange'] as num?)?.toDouble() ?? 0.0,
          ((d['remainingBlocks'] as num?)?.toInt() ?? 0).toDouble(),
        ];
      }, <double>[double.nan, double.nan]),
      safe('Lightning', () async {
        final r = await _get('/v1/lightning/statistics/latest');
        final d = jsonDecode(r.body) as Map<String, dynamic>;
        final latest = d['latest'] as Map<String, dynamic>? ?? d;
        final capSats = (latest['total_capacity'] as num?)?.toDouble() ?? 0;
        return [
          capSats / 1e8, // Sats -> BTC
          ((latest['node_count'] as num?)?.toInt() ?? 0).toDouble(),
          ((latest['channel_count'] as num?)?.toInt() ?? 0).toDouble(),
        ];
      }, <double>[-1, -1, -1]),
    ]);

    final height0 = results[0] as int;
    if (height0 > 0) ok++; // Blockhöhe zählt als eigene Quelle

    // MONOTONIE-GUARD: Die Blockhöhe darf niemals sinken.
    // Ersetzt den alten `height0 > 0 ? height0 : prev?.blockHeight`-Guard,
    // der bei jedem Fehlschlag stillschweigend den RAM-Stand DIESES Isolates
    // zurückschrieb — und damit einen frischeren Wert aus einem anderen
    // Isolate überbügelte.
    final lastKnown = await _loadLastHeight();
    final height = height0 > lastKnown ? height0 : lastKnown;

    if (height0 > lastKnown) {
      await _saveLastHeight(height0); // neuer Höchststand -> persistieren
    } else if (height0 == 0 && lastKnown > 0) {
      AppLogger.diag(_tag,
          'Blockhöhe NICHT geladen — zeige letzten bekannten Stand ($lastKnown). '
          'Das Widget behält damit den frischesten Wert, egal welcher Aufrufer zuletzt schreibt.');
    } else if (height0 > 0 && height0 < lastKnown) {
      // Kommt vor: veraltete CDN-Antwort. Früher hätte das die Anzeige
      // zurückgesetzt — jetzt wird der Rückschritt verworfen.
      AppLogger.diag(_tag,
          'Veraltete Blockhöhe verworfen: Server meldet $height0, bekannt ist bereits $lastKnown.');
    }

    final fees0 = results[1] as List<int>;

    final prices = results[2] as Map<String, double>;
    if (prices.isNotEmpty) ok++; // eigene Quelle, fängt intern ab

    final hashrate0 = results[3] as double;
    final diff0 = results[4] as List<double>;
    final ln0 = results[5] as List<double>;

    // FALLBACK-GUARDS: Ein guter alter Wert darf NIE von einem Fehlerwert
    // überschrieben werden — sonst zeigt die Kachel plötzlich "––".
    // Fehlerwerte sind jetzt eindeutig (-1 / NaN) statt 0, damit ein echter
    // Wert von 0 (z.B. Fee = 0 sat/vB gibt es nicht, aber Difficulty 0.0 %
    // sehr wohl!) nicht fälschlich als Fehler gilt.
    //
    // `height` wird hier BEWUSST nicht mehr gesetzt — die Blockhöhe kommt
    // oben aus dem Monotonie-Guard und ist damit isolate-übergreifend sicher.

    final fees = fees0[0] >= 0
        ? fees0
        : [prev?.feeLow ?? 0, prev?.feeMedium ?? 0, prev?.feeHigh ?? 0];

    final hashrate = hashrate0 >= 0 ? hashrate0 : (prev?.hashrateEhs ?? 0.0);

    final diff = !diff0[0].isNaN
        ? diff0
        : [
            prev?.difficultyChangePct ?? 0.0,
            (prev?.difficultyRemainingBlocks ?? 0).toDouble(),
          ];

    final ln = ln0[0] >= 0
        ? ln0
        : [
            prev?.lnCapacityBtc ?? 0.0,
            (prev?.lnNodeCount ?? 0).toDouble(),
            (prev?.lnChannelCount ?? 0).toDouble(),
          ];

    if (ok == 0) {
      AppLogger.warn(_tag,
          'ALLE Quellen fehlgeschlagen @ ${MempoolConfig.host}'
          '${_lastBlocked ? ' — Server weist Anfragen ab (Cloudflare/Rate-Limit). Bei Tor: Onion-Adresse in den Einstellungen wählen.' : ''}');
      // Häufigste Ursache für einen Totalausfall aus dem Nichts: der Nutzer
      // hat Orbot an- oder ausgeschaltet, die Keep-alive-Sockets sind tot.
      // Verbindungspool wegwerfen, damit der nächste Versuch frisch startet.
      resetClient();
    } else if (ok < 6) {
      AppLogger.diag(_tag, 'Nur $ok von 6 Quellen geliefert.');
    }

    final data = BitcoinDashboardData(
      blockHeight: height,
      feeLow: fees[0],
      feeMedium: fees[1],
      feeHigh: fees[2],
      priceEur: prices['EUR'] ?? prev?.priceEur ?? 0,
      priceUsd: prices['USD'] ?? prev?.priceUsd ?? 0,
      supply: height > 0 ? _circulatingSupply(height) : (prev?.supply ?? 0),
      hashrateEhs: hashrate,
      difficultyChangePct: diff[0],
      difficultyRemainingBlocks: diff[1].toInt(),
      lnCapacityBtc: ln[0],
      lnNodeCount: ln[1].toInt(),
      lnChannelCount: ln[2].toInt(),
      updatedAt: DateTime.now(),
      sourcesOk: ok,
      sourcesTotal: 6,
      lastError: _lastError,
      blocked: _lastBlocked,
    );

    // Nur speichern, wenn wenigstens EINE Quelle geliefert hat — sonst würden
    // wir einen guten Datensatz durch einen leeren ersetzen.
    if (ok > 0) lastDashboard = data;
    return data;
  }
}
