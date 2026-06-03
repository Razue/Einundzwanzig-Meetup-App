import 'vouching_service.dart';

/// Ein Knoten im Vertrauenspfad.
class TrustPathNode {
  final String npub;
  final String name;
  final String meetup;
  TrustPathNode({required this.npub, this.name = '', this.meetup = ''});
}

/// Ergebnis einer Pfadsuche.
class TrustPathResult {
  final List<TrustPathNode> path; // von mir bis Ziel (inkl. beider Enden)
  final bool found;
  final bool selfIsInNetwork; // Bin ich selbst im Bürgen-Netz?
  final bool targetIsInNetwork; // Ist das Ziel im Bürgen-Netz?

  TrustPathResult({
    required this.path,
    required this.found,
    required this.selfIsInNetwork,
    required this.targetIsInNetwork,
  });

  /// Anzahl der "Sprünge" (Kanten) zwischen mir und dem Ziel.
  int get degrees => path.isEmpty ? 0 : path.length - 1;
}

/// Findet den kürzesten Vertrauenspfad zwischen zwei npubs im Web of Trust.
///
/// Datengrundlage: das Bürgschafts-/Admin-Netz (VouchingService.calculateConsensus).
/// Bürgschaften werden als UNGERICHTETE Vertrauensverbindungen behandelt
/// ("A bürgt für B" => A und B sind verbunden), weil für die Frage
/// "über wen kenne ich diese Person" die Richtung zweitrangig ist.
class TrustPathService {
  /// Sucht den kürzesten Pfad von [fromNpub] zu [toNpub].
  static Future<TrustPathResult> findPath({
    required String fromNpub,
    required String toNpub,
  }) async {
    final consensus = await VouchingService.calculateConsensus();
    final nodes = consensus.allAdmins;

    // Lookup für Anzeige-Infos
    final info = <String, TrustPathNode>{};
    for (final s in nodes) {
      info[s.npub] = TrustPathNode(npub: s.npub, name: s.name, meetup: s.meetup);
    }

    // Ungerichtete Adjazenzliste aus den Bürgschaften aufbauen
    final adj = <String, Set<String>>{};
    void addEdge(String a, String b) {
      adj.putIfAbsent(a, () => <String>{}).add(b);
      adj.putIfAbsent(b, () => <String>{}).add(a);
    }

    for (final s in nodes) {
      for (final voucher in s.vouchers) {
        addEdge(s.npub, voucher);
        // Auch Voucher, die selbst nicht in allAdmins sind, als Knoten kennen
        info.putIfAbsent(voucher, () => TrustPathNode(npub: voucher));
      }
    }

    final selfIn = adj.containsKey(fromNpub);
    final targetIn = adj.containsKey(toNpub) || info.containsKey(toNpub);

    // Sonderfall: gleiche Person
    if (fromNpub == toNpub) {
      return TrustPathResult(
        path: [info[fromNpub] ?? TrustPathNode(npub: fromNpub)],
        found: true,
        selfIsInNetwork: selfIn,
        targetIsInNetwork: targetIn,
      );
    }

    // BFS für kürzesten Pfad
    if (!adj.containsKey(fromNpub)) {
      return TrustPathResult(
        path: const [],
        found: false,
        selfIsInNetwork: selfIn,
        targetIsInNetwork: targetIn,
      );
    }

    final visited = <String>{fromNpub};
    final queue = <List<String>>[
      [fromNpub]
    ];

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final last = current.last;
      if (last == toNpub) {
        final path = current
            .map((n) => info[n] ?? TrustPathNode(npub: n))
            .toList();
        return TrustPathResult(
          path: path,
          found: true,
          selfIsInNetwork: selfIn,
          targetIsInNetwork: targetIn,
        );
      }
      for (final neighbor in (adj[last] ?? const <String>{})) {
        if (!visited.contains(neighbor)) {
          visited.add(neighbor);
          queue.add([...current, neighbor]);
        }
      }
    }

    // Kein Pfad gefunden
    return TrustPathResult(
      path: const [],
      found: false,
      selfIsInNetwork: selfIn,
      targetIsInNetwork: targetIn,
    );
  }
}
