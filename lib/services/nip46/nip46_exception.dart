// Fehler des Remote-Signer-Transports (NIP-46).
//
// Getrennt von SigningException, weil hier eine Ebene tiefer liegt: der
// Client weiss nichts von Signier-Modi. Der SigningService uebersetzt diese
// Fehler in seine eigenen, damit die Aufrufer in der App nur eine Fehlerwelt
// kennen.

class Nip46Exception implements Exception {
  final String message;
  const Nip46Exception(this.message);

  @override
  String toString() => message;
}

/// Der Signer hat geantwortet, aber einen Fehler gemeldet — typischerweise
/// weil der Nutzer die Freigabe verweigert hat.
class Nip46RemoteException extends Nip46Exception {
  const Nip46RemoteException(super.message);
}

/// Innerhalb der Frist kam keine Antwort. Das ist der haeufigste Fall im
/// Alltag: die Signer-App liegt im Hintergrund oder das Geraet schlief.
///
/// [undecryptable] zaehlt die Ereignisse, die in dieser Sitzung nicht
/// entschluesselt werden konnten. Ein Wert > 0 bei einem Timeout ist der
/// Hinweis darauf, dass der Signer zwar antwortet, aber mit einem anderen
/// Schluessel — sonst waere die Ursache nicht von "gar keine Antwort" zu
/// unterscheiden.
class Nip46TimeoutException extends Nip46Exception {
  final String method;
  final Duration limit;
  final int undecryptable;

  /// Ereignisse, die von einem ANDEREN als dem gekoppelten Signer kamen.
  ///
  /// Getrennt von [undecryptable], weil beide auf Verschiedenes deuten:
  /// unlesbar heisst „richtiger Absender, falscher Schlüssel", fremder
  /// Absender heisst „jemand anderes antwortet". Ohne diesen Zähler war
  /// `undecryptable == 0` scheinbar ein Beweis, dass gar nichts ankam — und
  /// genau das war er nicht, denn Fremdantworten wurden spurlos verworfen.
  final int foreignSender;

  const Nip46TimeoutException(this.method, this.limit, this.undecryptable,
      [this.foreignSender = 0])
      : super('Der Signer hat nicht geantwortet.');

  @override
  String toString() => 'Nip46TimeoutException($method nach '
      '${limit.inSeconds}s ohne Antwort, $undecryptable unlesbare Ereignisse, '
      '$foreignSender von fremdem Absender)';
}

/// Alle Relays haben die Anfrage abgewiesen (`["OK", …, false, "<Grund>"]`).
///
/// Eigener Typ, weil der Grund vom Relay kommt und nicht vom Signer: der
/// Signer hat die Anfrage nie gesehen. Vorher lief dieser Fall stumm in die
/// vollen 75 Sekunden und meldete „Der Signer hat nicht geantwortet" —
/// obwohl das Relay einen Grund genannt hatte.
class Nip46RelayRejectedException extends Nip46Exception {
  final String reason;

  /// Bewusst NICHT const: der Grund muss in die Meldung hinein. Die
  /// Oberfläche zeigt `message` an — stünde der Grund nur in `reason`, bekäme
  /// der Nutzer wieder nur „irgendwas ging schief" zu sehen, und der ganze
  /// Zweck dieser Auswertung wäre verfehlt.
  Nip46RelayRejectedException(this.reason)
      : super('Das Relay hat die Anfrage abgewiesen: $reason');

  @override
  String toString() => 'Nip46RelayRejectedException($reason)';
}
