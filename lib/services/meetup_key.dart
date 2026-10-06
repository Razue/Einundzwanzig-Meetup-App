// ============================================
// MEETUP-KENNUNG — EINE Regel fuer Organisator und Teilnehmer
// ============================================
//
// Die signierte Meetup-Kennung im Badge (Feld `m`) hat die Form
//
//   <stadt-slug>-<land>      z. B. "bad-neuenahr-de", "aschaffenburg-de"
//
// Der Slug ist der Stadtname in Kleinbuchstaben, Leerzeichen durch
// Bindestriche ersetzt. Das Land ist der zweistellige ISO-3166-Code.
//
// DER FEHLER, DEN DIESE DATEI BEHEBT
// ----------------------------------
// Frueher signierte der Organisator nur den Slug ("bad-neuenahr"), und die
// Teilnehmer-App zerlegte JEDE Kennung am letzten Bindestrich: Stadt "bad",
// Land "NEUENAHR". Organisator und Teilnehmer bildeten daraus zwei
// verschiedene Netzwerk-Kennungen —
//
//   Organisator:  bad-neuenahr-2026-10-05@…
//   Teilnehmer:   bad-2026-10-05@…
//
// — und wer gemeinsam vor Ort war, erschien nicht als 1. Grad. Betroffen war
// jedes Meetup mit Leerzeichen oder Bindestrich im Namen (Frankfurt am Main,
// Neu-Ulm, Rothenburg ob der Tauber …).
//
// JETZT
// -----
//   - Der Organisator haengt das Land IMMER an, sobald es bekannt ist. Damit
//     zerlegen auch AELTERE Teilnehmer-Apps richtig: "bad-neuenahr-de" wird
//     auch dort zu "bad-neuenahr" + "DE".
//   - Zerlegt wird nur noch, wenn der letzte Teil ein echter ISO-Ländercode
//     ist. "bad-neuenahr" und "frankfurt-am-main" bleiben ganz.
//   - Die Netzwerk-Kennung entsteht auf beiden Seiten aus DIESEM Slug, nie
//     aus dem Anzeigenamen.
//
// Die Datei ist bewusst frei von Flutter und Netz — reine Funktionen, damit
// sie sich ohne Geraet testen laesst (test/meetup_key_test.dart).
// ============================================

/// Ergebnis der Zerlegung einer signierten Meetup-Kennung.
class ParsedMeetupId {
  /// Stadt-Slug, z. B. "bad-neuenahr". Grundlage der Netzwerk-Kennung.
  final String slug;

  /// ISO-Laendercode in Grossbuchstaben ("DE"), leer wenn keiner dabei ist.
  final String country;

  const ParsedMeetupId(this.slug, this.country);

  @override
  String toString() => 'ParsedMeetupId($slug, $country)';
}

class MeetupKey {
  MeetupKey._();

  /// Slug aus einem Stadt- oder Meetup-Namen.
  ///
  /// GENAU dieselbe Umformung wie seit jeher beim Organisator
  /// (`toLowerCase().replaceAll(' ', '-')`) — nur zusaetzlich getrimmt. So
  /// bleiben alle bisherigen Netzwerk-Kennungen gueltig.
  static String slug(String name) =>
      name.trim().toLowerCase().replaceAll(' ', '-');

  /// Signierte Kennung fuer das Badge: Slug plus Land, wenn bekannt.
  ///
  /// Ohne gueltiges Land (frei eingegebener Name) bleibt es beim Slug.
  static String compose(String slug, String country) {
    final c = country.trim().toUpperCase();
    if (slug.isEmpty) return slug;
    if (!isIsoCountry(c)) return slug;
    return '$slug-${c.toLowerCase()}';
  }

  /// Zerlegt eine signierte Kennung in Slug und Land.
  ///
  /// Nur wenn der letzte Teil ein gueltiger ISO-Code ist, wird er als Land
  /// abgetrennt. Sonst gehoert er zum Namen — "bad-neuenahr" ist eine Stadt,
  /// kein "bad" im Land "NEUENAHR".
  static ParsedMeetupId parse(String m) {
    final v = m.trim();
    final i = v.lastIndexOf('-');
    if (i <= 0 || i == v.length - 1) return ParsedMeetupId(v, '');
    final last = v.substring(i + 1).toUpperCase();
    if (!isIsoCountry(last)) return ParsedMeetupId(v, '');
    return ParsedMeetupId(v.substring(0, i), last);
  }

  /// Anzeigename aus einem Slug, wenn das Portal ihn nicht kennt:
  /// "bad-neuenahr" → "Bad Neuenahr".
  ///
  /// Verlustbehaftet: Ob im Original ein Leerzeichen oder ein Bindestrich
  /// stand ("Neu-Ulm"), laesst sich am Slug nicht mehr erkennen. Deshalb
  /// wird der Name, wo moeglich, aus der Portal-Liste genommen.
  static String displayFromSlug(String slug) => slug
      .split('-')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');

  /// Netzwerk-Kennungs-Stamm fuer ein Meetup an einem Tag:
  /// "bad-neuenahr-2026-10-05". Der Signierer-Anhang kommt im
  /// CoAttendanceService dazu.
  static String eventId(String slug, DateTime date) =>
      '$slug-${date.toIso8601String().substring(0, 10)}';

  static bool isIsoCountry(String code) =>
      code.length == 2 && _iso3166.contains(code.toUpperCase());

  /// ISO 3166-1 alpha-2, alle offiziell vergebenen Codes.
  static const Set<String> _iso3166 = {
    'AD', 'AE', 'AF', 'AG', 'AI', 'AL', 'AM', 'AO', 'AQ', 'AR', 'AS', 'AT',
    'AU', 'AW', 'AX', 'AZ', 'BA', 'BB', 'BD', 'BE', 'BF', 'BG', 'BH', 'BI',
    'BJ', 'BL', 'BM', 'BN', 'BO', 'BQ', 'BR', 'BS', 'BT', 'BV', 'BW', 'BY',
    'BZ', 'CA', 'CC', 'CD', 'CF', 'CG', 'CH', 'CI', 'CK', 'CL', 'CM', 'CN',
    'CO', 'CR', 'CU', 'CV', 'CW', 'CX', 'CY', 'CZ', 'DE', 'DJ', 'DK', 'DM',
    'DO', 'DZ', 'EC', 'EE', 'EG', 'EH', 'ER', 'ES', 'ET', 'FI', 'FJ', 'FK',
    'FM', 'FO', 'FR', 'GA', 'GB', 'GD', 'GE', 'GF', 'GG', 'GH', 'GI', 'GL',
    'GM', 'GN', 'GP', 'GQ', 'GR', 'GS', 'GT', 'GU', 'GW', 'GY', 'HK', 'HM',
    'HN', 'HR', 'HT', 'HU', 'ID', 'IE', 'IL', 'IM', 'IN', 'IO', 'IQ', 'IR',
    'IS', 'IT', 'JE', 'JM', 'JO', 'JP', 'KE', 'KG', 'KH', 'KI', 'KM', 'KN',
    'KP', 'KR', 'KW', 'KY', 'KZ', 'LA', 'LB', 'LC', 'LI', 'LK', 'LR', 'LS',
    'LT', 'LU', 'LV', 'LY', 'MA', 'MC', 'MD', 'ME', 'MF', 'MG', 'MH', 'MK',
    'ML', 'MM', 'MN', 'MO', 'MP', 'MQ', 'MR', 'MS', 'MT', 'MU', 'MV', 'MW',
    'MX', 'MY', 'MZ', 'NA', 'NC', 'NE', 'NF', 'NG', 'NI', 'NL', 'NO', 'NP',
    'NR', 'NU', 'NZ', 'OM', 'PA', 'PE', 'PF', 'PG', 'PH', 'PK', 'PL', 'PM',
    'PN', 'PR', 'PS', 'PT', 'PW', 'PY', 'QA', 'RE', 'RO', 'RS', 'RU', 'RW',
    'SA', 'SB', 'SC', 'SD', 'SE', 'SG', 'SH', 'SI', 'SJ', 'SK', 'SL', 'SM',
    'SN', 'SO', 'SR', 'SS', 'ST', 'SV', 'SX', 'SY', 'SZ', 'TC', 'TD', 'TF',
    'TG', 'TH', 'TJ', 'TK', 'TL', 'TM', 'TN', 'TO', 'TR', 'TT', 'TV', 'TW',
    'TZ', 'UA', 'UG', 'UM', 'US', 'UY', 'UZ', 'VA', 'VC', 'VE', 'VG', 'VI',
    'VN', 'VU', 'WF', 'WS', 'YE', 'YT', 'ZA', 'ZM', 'ZW',
  };
}
