/// Fehler beim Sprechen mit einer NIP-07-Browsererweiterung.
///
/// In eigener Datei, damit Stub und Web-Umsetzung sie teilen koennen, ohne
/// dass ein bedingter Export im Spiel ist — und ohne Import-Zyklus zum
/// SigningService, der die Klasse benutzt.
class Nip07Exception implements Exception {
  final String message;
  const Nip07Exception(this.message);

  @override
  String toString() => 'Nip07Exception: $message';
}

/// Der Nutzer hat die Anfrage in der Erweiterung abgelehnt.
///
/// Eigener Typ, weil das KEIN Fehler ist, den man dem Nutzer als roten
/// Balken zeigt — er hat sich bewusst entschieden.
class Nip07RejectedException extends Nip07Exception {
  const Nip07RejectedException()
      : super('Anfrage in der Erweiterung abgelehnt.');
}
