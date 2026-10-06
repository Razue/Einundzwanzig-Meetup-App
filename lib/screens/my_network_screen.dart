import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/badge.dart';
import '../models/user.dart';
import '../services/coattendance_service.dart';
import '../services/haptic_service.dart';
import '../services/nostr_profile_service.dart';
import '../theme.dart';
import '../widgets/npub_chip.dart';
import 'verify_person_screen.dart';

/// Das eigene Vertrauensnetzwerk (Grad 1–3).
///
/// Aufbau von oben nach unten:
///   Reichweite (Gesamtzahl, Verteilung, Stand der Daten)
///   → Graph als Baum: Du → direkte Kontakte → deren Kontakte → eine Ebene weiter
///   → Filter und Suche
///   → eine Liste mit Name UND npub je Person
///   → eingeklappte Erklaerung
///
/// Antippen einer Person (im Graphen oder in der Liste) oeffnet das Detail
/// mit dem Weg dorthin: "Du → Anna → Carla", je Schritt das Meetup, bei dem
/// sich die beiden begegnet sind. Erst von dort geht es nach Nostr.
class MyNetworkScreen extends StatefulWidget {
  const MyNetworkScreen({super.key});

  @override
  State<MyNetworkScreen> createState() => _MyNetworkScreenState();
}

class _MyNetworkScreenState extends State<MyNetworkScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  MyNetwork? _net;
  late AnimationController _pulse;

  /// Teilnahmen, die zugestimmt, aber nicht veroeffentlicht wurden.
  int _failedCount = 0;
  bool _retrying = false;

  /// Laeuft gerade eine Aktualisierung im Hintergrund?
  bool _updating = false;

  /// Bis zu welchem Grad die laufende Aktualisierung fertig ist (0 = keiner).
  int _doneDepth = 0;

  /// Die letzte Aktualisierung kam nicht zustande — gezeigt wird der
  /// gespeicherte Stand.
  bool _updateFailed = false;

  /// Anzeigenamen je npub. Fehlt einer, steht der gekuerzte npub da.
  final Map<String, String> _names = {};

  /// Fuer welche npubs schon Namen angefragt wurden — jede Person nur einmal.
  final Set<String> _namesAsked = {};

  /// Hoechstens so viele Namen je Bildschirm. Weiter hinten in Grad 3
  /// scrollt kaum jemand, und jede Person kostet eine Zeile in der Abfrage.
  static const int _maxNames = 400;

  /// 0 = alle, sonst der Grad.
  int _filter = 0;
  String _query = '';
  final TextEditingController _search = TextEditingController();

  /// Grade, deren Liste ganz aufgeklappt ist.
  final Set<int> _expanded = {};

  /// Liste je Grad zeigt anfangs so viele Eintraege.
  static const int _listPreview = 20;

  /// Im Graphen hervorgehobene Person (waehrend ihr Detail offen ist).
  String? _highlight;

  /// So viele direkte Kontakte zeigt der Graph — mehr wird auf dem Handy
  /// unlesbar. Der Rest steht als "8 von 12" darunter.
  static const int _graphDirect = 8;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _load();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _search.dispose();
    super.dispose();
  }

  // ============================================================
  // LADEN
  // ============================================================

  /// Laedt das Netzwerk.
  ///
  /// Ablauf: gespeicherten Stand SOFORT zeigen, dann im Hintergrund Grad
  /// fuer Grad aktualisieren. [forceFull]: alles neu holen statt nur das
  /// Neue (Herunterziehen).
  Future<void> _load({bool forceFull = false}) async {
    try {
      final user = await UserProfile.load();
      if (user.nostrNpub.isEmpty) {
        if (mounted) setState(() { _loading = false; _net = null; });
        return;
      }
      final npub = user.nostrNpub;

      if (_net == null) {
        final cached = await CoAttendanceService.cachedNetwork(myNpub: npub);
        if (cached != null && mounted) {
          setState(() { _net = cached; _loading = false; });
          _loadNames(cached);
        }
      }
      if (!mounted) return;
      setState(() {
        _updating = true;
        _doneDepth = 0;
        _updateFailed = false;
      });

      // Wie viele eigene Teilnahmen sind zugestimmt, aber nicht angekommen?
      // Laeuft parallel zum Netzwerk — beides ist unabhaengig.
      final failedFuture = MeetupBadge.loadBadges()
          .then(CoAttendanceService.failedBadges)
          .catchError((Object _) => <MeetupBadge>[]);

      final net = await CoAttendanceService.buildMyNetwork(
        myNpub: npub,
        forceFull: forceFull,
        onStage: (partial, depth) {
          if (!mounted) return;
          setState(() {
            _net = partial;
            _doneDepth = depth;
            _loading = false;
          });
        },
      );
      final failed = await failedFuture;
      if (!mounted) return;
      setState(() {
        // Ohne Relay-Antwort und ohne Cache bleibt das, was schon da ist.
        if (!(net.stale && net.isEmpty && _net != null)) _net = net;
        _failedCount = failed.length;
        _updating = false;
        _updateFailed = net.stale;
        _loading = false;
      });
      final shown = _net;
      if (shown != null) _loadNames(shown);
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _updating = false;
          _updateFailed = _net != null;
        });
      }
    }
  }

  /// Holt die Anzeigenamen — erst die gespeicherten (sofort), dann die
  /// fehlenden in einem Rutsch von den Relays.
  Future<void> _loadNames(MyNetwork net) async {
    final hexOf = <String, String>{};
    for (final npub in net.contactsByNpub.keys) {
      if (hexOf.length >= _maxNames) break;
      if (_namesAsked.contains(npub)) continue;
      try {
        hexOf[npub] = CoAttendanceService.npubToHex(npub);
      } catch (_) {}
    }
    if (hexOf.isEmpty) return;
    _namesAsked.addAll(hexOf.keys);

    void apply(Map<String, String> byHex) {
      final found = <String, String>{};
      hexOf.forEach((npub, hex) {
        final n = byHex[hex];
        if (n != null && n.isNotEmpty) found[npub] = n;
      });
      if (found.isNotEmpty && mounted) setState(() => _names.addAll(found));
    }

    apply(await NostrProfileService.cachedDisplayNames());
    apply(await NostrProfileService.fetchDisplayNames(hexOf.values));
  }

  /// Sendet alle fehlgeschlagenen Teilnahmen erneut und laedt dann neu.
  Future<void> _retry() async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _retrying = true);
    final badges = await MeetupBadge.loadBadges();
    final fixed = await CoAttendanceService.retryFailed(badges);
    if (!mounted) return;
    setState(() => _retrying = false);
    messenger.showSnackBar(SnackBar(
      content: Text(t.mnRetryResult(fixed, _failedCount)),
      backgroundColor: fixed > 0 ? cGreen : cRed,
    ));
    // Neu laden: Die jetzt angekommenen Teilnahmen erweitern das Netzwerk.
    _load();
  }

  // ============================================================
  // HILFEN FUER DIE ANZEIGE
  // ============================================================

  static Color _colorFor(int degree) =>
      degree == 1 ? cGreen : (degree == 2 ? cCyan : cOrange);

  String _short(String npub) => NpubChip.shorten(npub, head: 10, tail: 8);

  /// Name, sonst gekuerzter npub.
  String _label(String npub, AppLocalizations t) {
    if (npub == _net?.myNpub) return t.mnYou;
    return _names[npub] ?? _short(npub);
  }

  /// Anfangsbuchstabe des Namens — leer, wenn keiner bekannt ist.
  String _initial(String npub) {
    final n = _names[npub]?.trim();
    if (n == null || n.isEmpty) return '';
    return String.fromCharCode(n.runes.first).toUpperCase();
  }

  String _degreeLabel(AppLocalizations t, int degree) => degree == 1
      ? t.mnDegreeDirect
      : (degree == 2 ? t.mnDegreeSecond : t.mnDegreeThird);

  /// Zweite Zeile einer Person: woher man sie kennt.
  String _detailLine(AppLocalizations t, MyNetwork net, NetworkContact c) {
    if (c.degree == 1) {
      final n = c.sharedMeetupsWithMe.length;
      if (n == 0) return '';
      final parts = <String>[
        n == 1 ? t.mnOneSharedMeetup : t.mnSharedMeetups(n),
      ];
      final newest =
          AttendanceKeyLabel.newestFirst(c.sharedMeetupsWithMe).first;
      final d = AttendanceKeyLabel.date(newest);
      final place = AttendanceKeyLabel.place(newest);
      parts.add(t.mnLastAt(d == null
          ? place
          : '$place, ${AttendanceKeyLabel.dateText(d, withYear: false)}'));
      return parts.join(' · ');
    }
    if (c.degree == 3) {
      final path = net.pathTo(c.npub);
      if (path.length >= 3) {
        final middle = path.sublist(1, path.length - 1);
        return t.mnVia(middle.map((p) => _label(p, t)).join(' → '));
      }
    }
    final bridges = c.bridges.map((b) => _label(b, t)).toList()..sort();
    if (bridges.isEmpty) return '';
    if (bridges.length == 1) return t.mnVia(bridges.first);
    if (bridges.length == 2) {
      return t.mnVia('${bridges[0]} ${t.mnAnd} ${bridges[1]}');
    }
    return t.mnVia('${bridges[0]}, ${bridges[1]} +${bridges.length - 2}');
  }

  // ============================================================
  // AUFBAU
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        backgroundColor: cDark,
        elevation: 0,
        title: Text(t.mnTitle,
            style: const TextStyle(
                color: cText,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3)),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded,
                color: cTextSecondary, size: 22),
            tooltip: t.mnHowItWorks,
            onPressed: () => _showInfo(t),
          ),
          IconButton(
            icon: const Icon(Icons.person_search_rounded,
                color: cTextSecondary, size: 22),
            tooltip: t.mnCheckPerson,
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const VerifyPersonScreen())),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: cOrange,
        backgroundColor: cCard,
        // Herunterziehen = alles neu holen. Nur so fallen auch Teilnahmen
        // auf, die von den Relays verschwunden sind — sonst geschieht das
        // einmal am Tag von selbst.
        onRefresh: () => _load(forceFull: true),
        child: _loading || ((_net == null || _net!.isEmpty) && _updating)
            ? _buildFirstLoad(t)
            : _net == null || _net!.isEmpty
                ? _buildEmpty(t)
                : _buildContent(t, _net!),
      ),
    );
  }

  /// Erster Aufbau ohne gespeicherten Stand: Spinner mit Fortschritt.
  Widget _buildFirstLoad(AppLocalizations t) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 120),
        const Center(
            child: CircularProgressIndicator(color: cOrange, strokeWidth: 2)),
        const SizedBox(height: 18),
        Text(
          _doneDepth == 0
              ? t.mnLoading
              : t.mnUpdating((_doneDepth + 1).clamp(1, 3)),
          textAlign: TextAlign.center,
          style: const TextStyle(color: cTextSecondary, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildEmpty(AppLocalizations t) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_updateFailed) ...[
          _savedStateHint(t),
          const SizedBox(height: 14),
        ],
        // Gerade im LEEREN Netzwerk wichtig: Oft ist es leer, weil die
        // eigenen Teilnahmen nie angekommen sind.
        if (_failedCount > 0) _failedBanner(t),
        const SizedBox(height: 60),
        const Icon(Icons.hub_outlined, color: cTextTertiary, size: 56),
        const SizedBox(height: 20),
        Text(t.mnEmpty,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: cText, fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Text(t.mnEmptySub,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: cTextSecondary, fontSize: 13, height: 1.5)),
        const SizedBox(height: 24),
        // Hier bleibt der Event-Hinweis sichtbar: Wer nur Event-Badges
        // hat, sieht sonst ein leeres Netzwerk und haelt es fuer einen
        // Fehler (Issue #57, Punkt 2).
        _infoBox(t.mnEventNote, Icons.info_outline_rounded),
      ],
    );
  }

  Widget _buildContent(AppLocalizations t, MyNetwork net) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        if (_failedCount > 0) _failedBanner(t),
        _reachCard(t, net),
        const SizedBox(height: 16),
        _graphCard(t, net),
        const SizedBox(height: 16),
        _filterRow(t, net),
        const SizedBox(height: 10),
        _searchField(t),
        const SizedBox(height: 6),
        ..._sections(t, net),
        const SizedBox(height: 18),
        _howItWorksRow(t),
      ],
    );
  }

  // ------------------------------------------------------------
  // Fehlende Teilnahmen
  // ------------------------------------------------------------

  /// Hinweis mit Knopf, solange Teilnahmen fehlen.
  ///
  /// Steht OBEN: Fehlt eine eigene Teilnahme, fehlen auch alle
  /// Verbindungen, die daran haengen — das ist der Grund, falls das
  /// Netzwerk kleiner aussieht als erwartet.
  Widget _failedBanner(AppLocalizations t) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        decoration: BoxDecoration(
          color: cOrange.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: cOrange.withValues(alpha: 0.45), width: 0.5),
        ),
        child: Row(children: [
          const Icon(Icons.cloud_off_rounded, color: cOrange, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(t.mnFailedBanner(_failedCount),
                style: const TextStyle(
                    color: cText, fontSize: 12.5, height: 1.4)),
          ),
          const SizedBox(width: 6),
          _retrying
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: cOrange))
              : TextButton(
                  onPressed: _retry,
                  child: Text(t.mnRetry,
                      style: const TextStyle(
                          color: cOrange, fontWeight: FontWeight.w700)),
                ),
        ]),
      );

  Widget _savedStateHint(AppLocalizations t) => Row(children: [
        const Icon(Icons.cloud_off_rounded, color: cTextTertiary, size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Text(t.mnUpdateFailed,
              style: const TextStyle(color: cTextTertiary, fontSize: 12)),
        ),
      ]);

  // ------------------------------------------------------------
  // Reichweite
  // ------------------------------------------------------------

  /// Rechts oben in der Reichweiten-Karte: laufende Aktualisierung, Hinweis
  /// auf den gespeicherten Stand oder die Uhrzeit der Daten.
  Widget _statusChip(AppLocalizations t, MyNetwork net) {
    const style = TextStyle(color: cTextSecondary, fontSize: 12);
    if (_updating) {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(strokeWidth: 1.6, color: cOrange)),
        const SizedBox(width: 6),
        Text(t.mnUpdating((_doneDepth + 1).clamp(1, 3)), style: style),
      ]);
    }
    if (_updateFailed) {
      return Tooltip(
        message: t.mnUpdateFailed,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off_rounded, color: cTextTertiary, size: 13),
          const SizedBox(width: 5),
          Text(t.mnSavedState, style: style),
        ]),
      );
    }
    final at = net.updatedAt;
    if (at == null) return const SizedBox.shrink();
    String two(int v) => v.toString().padLeft(2, '0');
    final now = DateTime.now();
    final sameDay =
        at.year == now.year && at.month == now.month && at.day == now.day;
    final time = sameDay
        ? '${two(at.hour)}:${two(at.minute)}'
        : '${AttendanceKeyLabel.dateText(at, withYear: false)} ${two(at.hour)}:${two(at.minute)}';
    return Text(t.mnStandAt(time), style: style);
  }

  Widget _reachCard(AppLocalizations t, MyNetwork net) {
    final d1 = net.degree1Count, d2 = net.degree2Count, d3 = net.degree3Count;
    final total = max(1, net.totalReach);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cTileBorder, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(t.mnReachTitle,
                style: const TextStyle(
                    color: cTextSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2)),
          ),
          _statusChip(t, net),
        ]),
        const SizedBox(height: 6),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
          Text('${net.totalReach}',
              style: const TextStyle(
                  color: cText,
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  height: 1)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(t.mnReachSub(net.myMeetupCount),
                style: const TextStyle(color: cTextSecondary, fontSize: 15)),
          ),
        ]),
        const SizedBox(height: 14),
        // Verteilung auf die Grade.
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: Row(children: [
              if (d1 > 0)
                Expanded(flex: d1, child: Container(color: cGreen)),
              if (d1 > 0 && (d2 > 0 || d3 > 0)) const SizedBox(width: 2),
              if (d2 > 0)
                Expanded(flex: d2, child: Container(color: cCyan)),
              if (d2 > 0 && d3 > 0) const SizedBox(width: 2),
              if (d3 > 0)
                Expanded(
                    flex: d3,
                    child: Container(color: cOrange.withValues(alpha: 0.6))),
              if (d1 + d2 + d3 == 0)
                Expanded(flex: total, child: Container(color: cSurface)),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        Text(t.mnReachSplit(d1, d2, d3),
            style: const TextStyle(color: cTextSecondary, fontSize: 13)),
      ]),
    );
  }

  // ------------------------------------------------------------
  // Graph
  // ------------------------------------------------------------

  Widget _graphCard(AppLocalizations t, MyNetwork net) {
    final directTotal = net.degree1Count;
    final directShown = min(directTotal, _graphDirect);
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF15171C), Color(0xFF0D0E12)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cTileBorder, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        SizedBox(
          height: 300,
          child: LayoutBuilder(builder: (ctx, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            final nodes = _layoutTree(net, size);
            final pathSet = _highlight == null
                ? const <String>{}
                : net.pathTo(_highlight!).toSet();
            return GestureDetector(
              onTapUp: (d) => _handleGraphTap(t, net, d.localPosition, nodes),
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (_, _) => CustomPaint(
                  painter: _TreePainter(
                    nodes: nodes,
                    pulse: _pulse.value,
                    highlight: pathSet,
                    youLabel: t.mnYou,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            );
          }),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: Row(children: [
            if (directTotal > directShown)
              Expanded(
                child: Text(t.mnGraphExcerpt(directShown, directTotal),
                    style:
                        const TextStyle(color: cTextSecondary, fontSize: 12)),
              )
            else
              const Spacer(),
            Text(t.mnTapShowsPath,
                style: const TextStyle(color: cTextTertiary, fontSize: 12)),
          ]),
        ),
      ]),
    );
  }

  /// Baum-Anordnung: die staerksten direkten Kontakte im Kreis um mich,
  /// ihre Kontakte (Grad 2) dahinter im selben Sektor, davon wiederum
  /// Grad 3. Jede Linie verbindet eine Person mit der, ueber die sie
  /// erreicht wird — nicht mehr alles mit der Mitte.
  List<_TreeNode> _layoutTree(MyNetwork net, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final nodes = <_TreeNode>[
      _TreeNode(npub: net.myNpub, degree: 0, pos: center, radius: 19),
    ];
    final direct = (net.byDegree[1] ?? const <NetworkContact>[])
        .take(_graphDirect)
        .toList();
    if (direct.isEmpty) return nodes;

    final childrenOf = <String, List<NetworkContact>>{};
    for (final d in [2, 3]) {
      for (final c in net.byDegree[d] ?? const <NetworkContact>[]) {
        final p = c.parent;
        if (p != null) childrenOf.putIfAbsent(p, () => []).add(c);
      }
    }

    final maxR = min(size.width, size.height) / 2;
    final r1 = maxR * 0.48, r2 = maxR * 0.77, r3 = maxR * 0.93;
    final sector = 2 * pi / direct.length;
    // Bei wenigen direkten Kontakten duerfen die Aeste breiter faechern.
    final spread = sector * (direct.length <= 3 ? 0.22 : 0.32);

    for (var i = 0; i < direct.length; i++) {
      final a = -pi / 2 + i * sector;
      final p1 = center + Offset(r1 * cos(a), r1 * sin(a));
      final c1 = direct[i];
      nodes.add(_TreeNode(
          npub: c1.npub,
          degree: 1,
          pos: p1,
          from: center,
          radius: 15,
          initial: _initial(c1.npub),
          contact: c1));

      final kids = (childrenOf[c1.npub] ?? const <NetworkContact>[])
          .take(3)
          .toList();
      for (var j = 0; j < kids.length; j++) {
        final a2 = a + (j - (kids.length - 1) / 2) * spread;
        final p2 = center + Offset(r2 * cos(a2), r2 * sin(a2));
        nodes.add(_TreeNode(
            npub: kids[j].npub,
            degree: 2,
            pos: p2,
            from: p1,
            radius: 6,
            contact: kids[j]));

        final grand = (childrenOf[kids[j].npub] ?? const <NetworkContact>[])
            .take(2)
            .toList();
        for (var q = 0; q < grand.length; q++) {
          final a3 = a2 + (q - (grand.length - 1) / 2) * 0.16;
          final p3 = center + Offset(r3 * cos(a3), r3 * sin(a3));
          nodes.add(_TreeNode(
              npub: grand[q].npub,
              degree: 3,
              pos: p3,
              from: p2,
              radius: 3.5,
              contact: grand[q]));
        }
      }
    }
    return nodes;
  }

  void _handleGraphTap(AppLocalizations t, MyNetwork net, Offset tap,
      List<_TreeNode> nodes) {
    _TreeNode? hit;
    var best = 24.0; // Toleranz in px
    for (final n in nodes) {
      if (n.contact == null) continue; // Mitte (ich) ignorieren
      final d = (n.pos - tap).distance;
      if (d < best) {
        best = d;
        hit = n;
      }
    }
    final c = hit?.contact;
    if (c != null) {
      HapticService.light();
      _openDetail(t, net, c);
    }
  }

  // ------------------------------------------------------------
  // Filter, Suche, Liste
  // ------------------------------------------------------------

  Widget _filterRow(AppLocalizations t, MyNetwork net) {
    Widget chip(int value, int count, String label, Color color) {
      final selected = _filter == value;
      return Expanded(
        child: Material(
          color: selected ? cOrange.withValues(alpha: 0.14) : cCard,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              HapticService.light();
              setState(() => _filter = value);
            },
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: selected ? cOrange : cTileBorder, width: 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$count',
                      style: TextStyle(
                          color: color,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          height: 1.1)),
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: selected ? cText : cTextSecondary,
                          fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Row(children: [
      chip(0, net.totalReach, t.mnFilterAll, cText),
      const SizedBox(width: 6),
      chip(1, net.degree1Count, t.mnDirectLabel, cGreen),
      const SizedBox(width: 6),
      chip(2, net.degree2Count, t.mnDegreeSecond, cCyan),
      const SizedBox(width: 6),
      chip(3, net.degree3Count, t.mnDegreeThird, cOrange),
    ]);
  }

  Widget _searchField(AppLocalizations t) => TextField(
        controller: _search,
        onChanged: (v) => setState(() => _query = v),
        style: const TextStyle(color: cText, fontSize: 15),
        decoration: InputDecoration(
          hintText: t.mnSearchHint,
          hintStyle: const TextStyle(color: cTextTertiary, fontSize: 15),
          prefixIcon:
              const Icon(Icons.search_rounded, color: cTextTertiary, size: 20),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: cTextTertiary, size: 18),
                  tooltip: t.mnClose,
                  onPressed: () {
                    _search.clear();
                    setState(() => _query = '');
                  },
                ),
          filled: true,
          fillColor: cSurface,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: cTileBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: cTileBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: cOrange),
          ),
        ),
      );

  List<Widget> _sections(AppLocalizations t, MyNetwork net) {
    final q = _query.trim().toLowerCase();
    final titles = {1: t.mnDegree1, 2: t.mnDegree2, 3: t.mnDegree3};
    final out = <Widget>[];

    for (final d in [1, 2, 3]) {
      if (_filter != 0 && _filter != d) continue;
      var list = net.byDegree[d] ?? const <NetworkContact>[];
      if (q.isNotEmpty) {
        list = list
            .where((c) =>
                c.npub.toLowerCase().contains(q) ||
                (_names[c.npub]?.toLowerCase().contains(q) ?? false))
            .toList();
      }
      if (list.isEmpty) continue;

      final color = _colorFor(d);
      final showAll = q.isNotEmpty || _expanded.contains(d);
      final shown = showAll ? list : list.take(_listPreview).toList();

      out.add(Padding(
        padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
        child: Text('${titles[d]!.toUpperCase()} · ${list.length}',
            style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2)),
      ));
      out.add(Container(
        decoration: BoxDecoration(
          color: cCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cTileBorder, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          for (var i = 0; i < shown.length; i++)
            _contactRow(t, net, shown[i], first: i == 0),
          if (shown.length < list.length)
            InkWell(
              onTap: () => setState(() => _expanded.add(d)),
              child: Container(
                height: 48,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  border:
                      Border(top: BorderSide(color: cTileBorder, width: 0.5)),
                ),
                child: Text(t.mnShowAll(list.length),
                    style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ),
            ),
        ]),
      ));
    }

    if (out.isEmpty) {
      out.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Text(q.isNotEmpty ? t.mnNoResults : '—',
            textAlign: TextAlign.center,
            style: const TextStyle(color: cTextTertiary, fontSize: 14)),
      ));
    }
    return out;
  }

  Widget _avatar(String npub, int degree, double size) {
    final color = degree == 0 ? cOrange : _colorFor(degree);
    final initial = _initial(npub);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      alignment: Alignment.center,
      child: initial.isEmpty
          ? Icon(Icons.person_outline_rounded,
              color: cTextSecondary, size: size * 0.45)
          : Text(initial,
              style: TextStyle(
                  color: cText,
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.w700)),
    );
  }

  /// Eine Person in der Liste: Name, npub, woher man sie kennt.
  Widget _contactRow(AppLocalizations t, MyNetwork net, NetworkContact c,
      {required bool first}) {
    final name = _names[c.npub];
    final detail = _detailLine(t, net, c);
    return InkWell(
      onTap: () => _openDetail(t, net, c),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          border: first
              ? null
              : const Border(
                  top: BorderSide(color: cTileBorder, width: 0.5)),
        ),
        child: Row(children: [
          _avatar(c.npub, c.degree, 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (name != null)
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: cText,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                  Text(_short(c.npub),
                      maxLines: 1,
                      style: TextStyle(
                          color: name == null ? cText : cTextTertiary,
                          fontSize: name == null ? 14 : 12,
                          fontFamily: fontMono)),
                  if (detail.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(detail,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: cTextSecondary, fontSize: 13)),
                    ),
                ]),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded,
              color: cTextTertiary, size: 20),
        ]),
      ),
    );
  }

  // ------------------------------------------------------------
  // Erklaerung
  // ------------------------------------------------------------

  Widget _howItWorksRow(AppLocalizations t) => Material(
        color: cSurface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showInfo(t),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cTileBorder, width: 0.5),
            ),
            child: Row(children: [
              const Icon(Icons.privacy_tip_outlined,
                  color: cTextTertiary, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.mnHowItWorks,
                          style: const TextStyle(
                              color: cText,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                      Text(t.mnHowItWorksSub,
                          style: const TextStyle(
                              color: cTextSecondary, fontSize: 13)),
                    ]),
              ),
              const Icon(Icons.expand_more_rounded,
                  color: cTextTertiary, size: 20),
            ]),
          ),
        ),
      );

  Widget _infoBox(String text, IconData icon, {Color color = cTextTertiary}) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cTileBorder, width: 0.5),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: cTextSecondary, fontSize: 13, height: 1.5)),
          ),
        ]),
      );

  /// Alle Erklaerungen gesammelt — vorher standen sie als vier Kaesten
  /// verteilt auf dem Bildschirm.
  void _showInfo(AppLocalizations t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.8),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _grabber(),
                  const SizedBox(height: 16),
                  Text(t.mnHowItWorks,
                      style: const TextStyle(
                          color: cText,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Text(t.mnIntro,
                      style: const TextStyle(
                          color: cTextSecondary, fontSize: 14, height: 1.5)),
                  const SizedBox(height: 14),
                  _infoBox(t.mnEventNote, Icons.event_busy_outlined),
                  const SizedBox(height: 10),
                  _infoBox(t.mnTrustHint, Icons.lightbulb_outline_rounded,
                      color: cOrange),
                  const SizedBox(height: 10),
                  _infoBox(t.mnPrivacyNote, Icons.privacy_tip_outlined),
                ]),
          ),
        ),
      ),
    );
  }

  Widget _grabber() => Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
              color: const Color(0xFF3A3A44),
              borderRadius: BorderRadius.circular(2)),
        ),
      );

  // ------------------------------------------------------------
  // Detail einer Person
  // ------------------------------------------------------------

  /// Detail mit dem Weg zur Person. Waehrenddessen ist der Weg im Graphen
  /// hervorgehoben.
  Future<void> _openDetail(
      AppLocalizations t, MyNetwork net, NetworkContact c) async {
    setState(() => _highlight = c.npub);
    await showModalBottomSheet(
      context: context,
      backgroundColor: cCard,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.75),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: _detailBody(ctx, t, net, c),
          ),
        ),
      ),
    );
    if (mounted) setState(() => _highlight = null);
  }

  Widget _detailBody(BuildContext ctx, AppLocalizations t, MyNetwork net,
      NetworkContact c) {
    final color = _colorFor(c.degree);
    final name = _names[c.npub];
    final title = name ?? _short(c.npub);

    // Weg: bei Grad 1 trivial, sonst aus den Vorgaengern.
    var path = net.pathTo(c.npub);
    if (path.isEmpty && c.degree == 1) path = [net.myNpub, c.npub];

    // Andere direkte Kontakte, ueber die die Person ebenfalls erreichbar ist.
    final others = c.bridges.where((b) => !path.contains(b)).toList()
      ..sort((a, b) => _label(a, t).compareTo(_label(b, t)));

    final shared = c.degree == 1
        ? AttendanceKeyLabel.newestFirst(c.sharedMeetupsWithMe)
        : const <String>[];

    const sectionStyle = TextStyle(
        color: cTextSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _grabber(),
      const SizedBox(height: 18),

      // Kopf: Name, Grad, npub zum Kopieren
      Row(children: [
        _avatar(c.npub, c.degree, 52),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: cText,
                          fontSize: name == null ? 16 : 20,
                          fontWeight: FontWeight.w700,
                          fontFamily: name == null ? fontMono : null)),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6)),
                    child: Text(_degreeLabel(t, c.degree),
                        style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                ]),
            _CopyNpub(npub: c.npub, label: _short(c.npub), tooltip: t.mnCopyNpub),
          ]),
        ),
      ]),

      // Der Weg
      if (path.length >= 2) ...[
        const SizedBox(height: 20),
        Text(t.mnPathTo(_label(c.npub, t)).toUpperCase(), style: sectionStyle),
        const SizedBox(height: 10),
        for (var i = 0; i < path.length; i++) ...[
          _pathNode(t, net, path[i]),
          if (i < path.length - 1) _pathLink(t, net, path[i], path[i + 1]),
        ],
      ],

      // Bei direkten Kontakten: alle gemeinsamen Meetups
      if (shared.isNotEmpty) ...[
        const SizedBox(height: 20),
        Text(t.mnSharedMeetupsList.toUpperCase(), style: sectionStyle),
        const SizedBox(height: 8),
        for (final k in shared)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              const Icon(Icons.groups_rounded, color: cGreen, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(AttendanceKeyLabel.label(k),
                    style: const TextStyle(color: cText, fontSize: 14)),
              ),
            ]),
          ),
      ],

      if (others.isNotEmpty) ...[
        const SizedBox(height: 20),
        Text(t.mnAlsoVia.toUpperCase(), style: sectionStyle),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final b in others.take(12))
            Container(
              padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
              decoration: BoxDecoration(
                color: cSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cTileBorder, width: 0.5),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _avatar(b, 1, 22),
                const SizedBox(width: 6),
                Text(_label(b, t),
                    style: TextStyle(
                        color: cText,
                        fontSize: 14,
                        fontFamily: _names[b] == null ? fontMono : null)),
              ]),
            ),
        ]),
      ],

      const SizedBox(height: 24),
      Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
                foregroundColor: cText,
                side: const BorderSide(color: cTileBorder),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              Navigator.pop(ctx);
              _openNostrProfile(c.npub);
            },
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: Text(t.mnOpenInNostr),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: cOrange,
                foregroundColor: cDark,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.mnClose,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    ]);
  }

  /// Eine Station auf dem Weg.
  Widget _pathNode(AppLocalizations t, MyNetwork net, String npub) {
    final isMe = npub == net.myNpub;
    final degree = isMe ? 0 : (net.contactsByNpub[npub]?.degree ?? 1);
    final name = _names[npub];
    return Row(children: [
      if (isMe)
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration:
              const BoxDecoration(color: cOrange, shape: BoxShape.circle),
          child: Text(t.mnYou,
              style: const TextStyle(
                  color: cDark, fontSize: 11, fontWeight: FontWeight.w700)),
        )
      else
        _avatar(npub, degree, 28),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          isMe ? t.mnYou : (name ?? _short(npub)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: cText,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontFamily: (!isMe && name == null) ? fontMono : null),
        ),
      ),
    ]);
  }

  /// Die Verbindung zwischen zwei Stationen — mit dem juengsten Meetup,
  /// bei dem sich die beiden begegnet sind.
  Widget _pathLink(AppLocalizations t, MyNetwork net, String a, String b) {
    final degree = net.contactsByNpub[b]?.degree ?? 1;
    final shared = net.sharedBetween(a, b);
    return SizedBox(
      height: 34,
      child: Row(children: [
        SizedBox(
          width: 28,
          child: Center(
            child: Container(width: 2, color: _colorFor(degree)),
          ),
        ),
        const SizedBox(width: 12),
        if (shared.isNotEmpty)
          Expanded(
            child: Text(t.mnTogetherAt(AttendanceKeyLabel.label(shared.first)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: cTextSecondary, fontSize: 13)),
          ),
      ]),
    );
  }

  /// Öffnet das Nostr-Profil: erst per nostr:-Schema (installierte App),
  /// Fallback auf njump.me im Browser.
  Future<void> _openNostrProfile(String npub) async {
    final nostrUri = Uri.parse('nostr:$npub');
    final webUri = Uri.parse('https://njump.me/$npub');
    try {
      if (!await launchUrl(nostrUri, mode: LaunchMode.externalApplication)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      try {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
  }
}

/// npub mit Kopier-Knopf. Bestaetigt das Kopieren am Knopf selbst — eine
/// Snackbar laege hinter dem offenen Detail und bliebe unsichtbar.
class _CopyNpub extends StatefulWidget {
  final String npub;
  final String label;
  final String tooltip;
  const _CopyNpub(
      {required this.npub, required this.label, required this.tooltip});

  @override
  State<_CopyNpub> createState() => _CopyNpubState();
}

class _CopyNpubState extends State<_CopyNpub> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.npub));
    HapticService.medium();
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Flexible(
        child: Text(widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: cTextSecondary, fontSize: 13, fontFamily: fontMono)),
      ),
      IconButton(
        tooltip: widget.tooltip,
        visualDensity: VisualDensity.compact,
        onPressed: _copy,
        icon: Icon(_copied ? Icons.check_rounded : Icons.copy_rounded,
            size: 16, color: _copied ? cGreen : cTextTertiary),
      ),
    ]);
  }
}

/// Ein Knoten im Baum-Graphen.
class _TreeNode {
  final String npub;
  final int degree; // 0 = ich, 1/2/3 = Grad
  final Offset pos;

  /// Position des Vorgaengers — von dort kommt die Linie. Null bei mir.
  final Offset? from;
  final double radius;

  /// Anfangsbuchstabe (nur bei Grad 1 gezeichnet), leer wenn unbekannt.
  final String initial;
  final NetworkContact? contact; // null bei mir

  _TreeNode({
    required this.npub,
    required this.degree,
    required this.pos,
    this.from,
    required this.radius,
    this.initial = '',
    this.contact,
  });
}

/// Zeichnet den Baum: Linien vom Vorgaenger zum Nachfolger, Knoten nach
/// Grad gefaerbt, die direkten Kontakte mit Anfangsbuchstaben, ich in der
/// Mitte. Ist ein Weg hervorgehoben, tritt alles andere zurueck.
class _TreePainter extends CustomPainter {
  final List<_TreeNode> nodes;
  final double pulse; // 0..1
  final Set<String> highlight;
  final String youLabel;

  _TreePainter({
    required this.nodes,
    required this.pulse,
    required this.highlight,
    required this.youLabel,
  });

  static Color _color(int degree) =>
      degree == 1 ? cGreen : (degree == 2 ? cCyan : cOrange);

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.isEmpty) return;
    final dimming = highlight.isNotEmpty;
    bool on(_TreeNode n) => !dimming || highlight.contains(n.npub);

    // 1. Linien — tiefe Grade zuerst, damit die naeheren obenauf liegen.
    for (final deg in [3, 2, 1]) {
      for (final n in nodes.where((n) => n.degree == deg && n.from != null)) {
        final active = on(n);
        final width = deg == 1 ? 1.6 : (deg == 2 ? 1.2 : 1.0);
        final baseAlpha = deg == 1 ? 0.6 : (deg == 2 ? 0.5 : 0.4);
        canvas.drawLine(
          n.from!,
          n.pos,
          Paint()
            ..color = _color(deg).withValues(
                alpha: dimming ? (active ? 1.0 : 0.12) : baseAlpha)
            ..strokeWidth = dimming && active ? 3 : width
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // 2. Knoten
    final target = _targetNpub;
    for (final deg in [3, 2, 1]) {
      for (final n in nodes.where((n) => n.degree == deg)) {
        final active = on(n);
        final color = _color(deg);
        final alpha = dimming && !active ? 0.18 : 1.0;
        final isTarget = dimming && active && n.npub == target;

        if (isTarget) {
          canvas.drawCircle(n.pos, n.radius + 8,
              Paint()..color = color.withValues(alpha: 0.25));
        }
        if (deg == 1) {
          canvas.drawCircle(n.pos, n.radius,
              Paint()..color = cCard.withValues(alpha: alpha));
          canvas.drawCircle(
              n.pos,
              n.radius,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = dimming && active ? 2.5 : 2
                ..color = color.withValues(alpha: alpha));
          if (n.initial.isNotEmpty) {
            _text(canvas, n.initial, n.pos,
                TextStyle(
                    color: cText.withValues(alpha: alpha),
                    fontSize: 13,
                    fontWeight: FontWeight.w700));
          } else {
            canvas.drawCircle(n.pos, 3,
                Paint()..color = cTextSecondary.withValues(alpha: alpha));
          }
        } else {
          final r = isTarget ? n.radius + 3 : n.radius;
          canvas.drawCircle(
              n.pos, r, Paint()..color = color.withValues(alpha: alpha));
          if (isTarget) {
            canvas.drawCircle(
                n.pos,
                r,
                Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 2
                  ..color = Colors.white);
          }
        }
      }
    }

    // 3. Ich in der Mitte
    final me = nodes.first;
    canvas.drawCircle(
        me.pos,
        me.radius + 6 + pulse * 3,
        Paint()
          ..color = cOrange.withValues(alpha: 0.14 + pulse * 0.08)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.drawCircle(me.pos, me.radius, Paint()..color = cOrange);
    _text(canvas, youLabel, me.pos,
        const TextStyle(
            color: cDark, fontSize: 14, fontWeight: FontWeight.w700));
  }

  /// Die angetippte Person ist das letzte Glied des Wegs — also die, die
  /// im Weg steht, aber selbst keinen hervorgehobenen Nachfolger hat.
  String? get _targetNpub {
    if (highlight.isEmpty) return null;
    for (final n in nodes) {
      if (n.degree == 0 || !highlight.contains(n.npub)) continue;
      final hasNext = nodes.any((m) =>
          m.from == n.pos && highlight.contains(m.npub) && m.degree > n.degree);
      if (!hasNext) return n.npub;
    }
    return null;
  }

  void _text(Canvas canvas, String text, Offset center, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _TreePainter old) =>
      old.pulse != pulse ||
      !identical(old.nodes, nodes) ||
      old.highlight.length != highlight.length ||
      !old.highlight.containsAll(highlight);
}
