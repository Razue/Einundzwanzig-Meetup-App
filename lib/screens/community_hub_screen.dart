// COMMUNITY-HUB
// ============================================
// Auswahlmenü hinter der "Community"-Kachel (Struktur C):
//   - PORTAL (groß)  -> PortalAreaScreen: Meetups, Events & Zusagen (RSVP),
//                       Kurse & Dozenten, Karte, Meine Meetups, Portal-Web
//   - News / Nostr / Shoutout / Podcast (bestehende Ziele, unverändert)
// Funktionen orientiert an der Open-Source-Companion-App
// (HolgerHatGarKeineNode/twenty-one-companion), Design = App-Theme.
// ============================================

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';
import '../services/portal_api_service.dart';
import 'calendar_screen.dart';
import 'community_portal_screen.dart' as legacy;
import 'news_screen.dart';
import 'nearby_meetups_screen.dart';
import 'portal_meetups_screen.dart';

Future<void> _openUrl(String url) async {
  final uri = Uri.parse(url);
  try { await launchUrl(uri, mode: LaunchMode.externalApplication); } catch (_) {}
}

class CommunityHubScreen extends StatelessWidget {
  const CommunityHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        backgroundColor: cDark, elevation: 0,
        title: Text(t.chTitle, style: const TextStyle(color: cText, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // PORTAL (groß)
            _bigCard(
              context,
              icon: Icons.public_rounded,
              color: cOrange,
              title: t.chPortal,
              subtitle: t.chPortalSub,
              chips: const ['Meetups', 'Events', 'Kurse', 'Karte'],
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PortalAreaScreen())),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _smallCard(context, icon: Icons.article_rounded, color: cOrange, title: t.chNews, subtitle: t.chNewsSub,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewsScreen())))),
              const SizedBox(width: 14),
              Expanded(child: _smallCard(context, icon: Icons.flutter_dash, color: cNostr, title: t.chNostr, subtitle: t.chNostrSub,
                  onTap: () => _openUrl('https://njump.me/npub1einundzwanzig'))),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _smallCard(context, icon: Icons.campaign_rounded, color: cOrange, title: t.chShoutout, subtitle: t.chShoutoutSub,
                  onTap: () => _openUrl('https://shoutout.einundzwanzig.space'))),
              const SizedBox(width: 14),
              Expanded(child: _smallCard(context, icon: Icons.podcasts_rounded, color: cPurple, title: t.chPodcast, subtitle: t.chPodcastSub,
                  onTap: () => _openUrl('https://einundzwanzig.space/podcast/'))),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _bigCard(BuildContext context, {required IconData icon, required Color color, required String title, required String subtitle, required List<String> chips, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cCard,
          borderRadius: BorderRadius.circular(kTileRadius + 2),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(kTileRadius + 2),
          child: Stack(children: [
            Positioned(right: -14, bottom: -14, child: Icon(icon, size: 110, color: color.withValues(alpha: 0.07))),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(width: 10),
                  Text(title, style: const TextStyle(color: cText, fontSize: 18, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded, color: color, size: 22),
                ]),
                const SizedBox(height: 6),
                Text(subtitle, style: const TextStyle(color: cTextSecondary, fontSize: 12.5)),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final c in chips)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: cSurface, borderRadius: BorderRadius.circular(8)),
                      child: Text(c, style: const TextStyle(color: cTextSecondary, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _smallCard(BuildContext context, {required IconData icon, required Color color, required String title, required String subtitle, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 130,
        decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(kTileRadius), border: Border.all(color: cTileBorder, width: 0.5)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(kTileRadius),
          child: Stack(children: [
            Positioned(right: -10, bottom: -10, child: Icon(icon, size: 72, color: color.withValues(alpha: 0.07))),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(icon, color: color, size: 22),
                const Spacer(),
                Text(title, style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: cTextTertiary, fontSize: 11.5)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ============================================
//  PORTAL-BEREICH (Ebene 2)
// ============================================
class PortalAreaScreen extends StatelessWidget {
  const PortalAreaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        backgroundColor: cDark, elevation: 0,
        title: Text(t.paTitle, style: const TextStyle(color: cText, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _row(context, Icons.groups_rounded, cOrange, t.paMeetups, t.paMeetupsSub,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen()))),
            _row(context, Icons.event_available_rounded, cGreen, t.paEvents, t.paEventsSub,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PortalEventsScreen()))),
            _row(context, Icons.school_rounded, cNostr, t.paCourses, t.paCoursesSub,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CoursesScreen()))),
            _row(context, Icons.map_rounded, cCyan, t.paMap, t.paMapSub,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NearbyMeetupsScreen()))),
            _row(context, Icons.edit_calendar_rounded, cOrange, t.paMine, t.paMineSub,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PortalMeetupsScreen()))),
            _row(context, Icons.language_rounded, cTextSecondary, t.paWeb, t.paWebSub,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const legacy.CommunityPortalScreen()))),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, Color color, String title, String sub, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(kTileRadius), border: Border.all(color: cTileBorder, width: 0.5)),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)),
          child: Icon(icon, color: color, size: 21),
        ),
        const SizedBox(width: 13),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(color: cTextTertiary, fontSize: 11.5)),
        ])),
        const Icon(Icons.chevron_right_rounded, color: cTextTertiary, size: 18),
      ]),
    ),
  );
}

// ============================================
//  EVENTS & ZUSAGEN (RSVP) — Companion-Feature
// ============================================
class PortalEventsScreen extends StatefulWidget {
  const PortalEventsScreen({super.key});

  @override
  State<PortalEventsScreen> createState() => _PortalEventsScreenState();
}

class _PortalEventsScreenState extends State<PortalEventsScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _events = [];
  final Map<int, Map<String, dynamic>> _rsvp = {}; // eventId -> {count, going}
  final Set<int> _busy = {};

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await PortalApiService.getAllMeetupEvents();
    // nur kommende, chronologisch
    final now = DateTime.now().subtract(const Duration(hours: 6));
    list.retainWhere((e) {
      final d = DateTime.tryParse((e['start'] ?? '').toString());
      return d != null && d.isAfter(now);
    });
    list.sort((a, b) => (a['start'] ?? '').toString().compareTo((b['start'] ?? '').toString()));
    if (!mounted) return;
    setState(() { _events = list; _loading = false; });
    // RSVP-Status der ersten 25 nachladen (sparsam)
    for (final e in list.take(25)) {
      final id = e['id'];
      if (id is! int) continue;
      final r = await PortalApiService.getRsvp(id);
      if (!mounted) return;
      if (r != null) setState(() => _rsvp[id] = r);
    }
  }

  Future<void> _doRsvp(int id) async {
    final t = AppLocalizations.of(context);
    if (!await PortalApiService.hasToken()) {
      _snack(t.rsvpNeedLogin, cRed);
      return;
    }
    setState(() => _busy.add(id));
    final res = await PortalApiService.rsvp(id);
    if (!mounted) return;
    setState(() => _busy.remove(id));
    if (res.ok) {
      final r = await PortalApiService.getRsvp(id);
      if (mounted && r != null) setState(() => _rsvp[id] = r);
    } else {
      _snack('${t.rsvpFailed}: ${res.error ?? ''}', cRed);
    }
  }

  void _snack(String msg, Color c) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: c, behavior: SnackBarBehavior.floating));

  String _fmt(String iso) {
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return iso;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year} · ${two(d.hour)}:${two(d.minute)}';
  }

  bool _isGoing(Map<String, dynamic>? r) {
    if (r == null) return false;
    final st = (r['status'] ?? '').toString();
    if (st == 'attending' || st == 'maybe') return true;
    final v = r['going'] ?? r['is_going'] ?? r['rsvped'];
    return v == true;
  }

  int _count(Map<String, dynamic>? r) {
    if (r == null) return -1;
    final v = r['attendees'] ?? r['count'] ?? r['total'] ?? r['rsvps'];
    return (v is int) ? v : -1;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        backgroundColor: cDark, elevation: 0,
        title: Text(t.paEvents, style: const TextStyle(color: cText, fontWeight: FontWeight.w700, fontSize: 17)),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded, color: cTextSecondary), onPressed: _loading ? null : _load)],
      ),
      body: SafeArea(
        child: _loading
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                const CircularProgressIndicator(color: cOrange),
                const SizedBox(height: 12),
                Text(t.rsvpLoading, style: const TextStyle(color: cTextSecondary, fontSize: 13)),
              ]))
            : _events.isEmpty
                ? Center(child: Text(t.rsvpNone, style: const TextStyle(color: cTextSecondary, fontSize: 14)))
                : RefreshIndicator(
                    color: cOrange, backgroundColor: cCard, onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _events.length,
                      itemBuilder: (_, i) => _eventCard(t, _events[i]),
                    ),
                  ),
      ),
    );
  }

  Widget _eventCard(AppLocalizations t, Map<String, dynamic> e) {
    final id = e['id'] is int ? e['id'] as int : -1;
    final r = _rsvp[id];
    final going = _isGoing(r);
    final count = _count(r);
    final meetupName = (e['meetup'] is Map ? ((e['meetup'] as Map)['name'] ?? '') : (e['meetup.name'] ?? e['meetup_name'] ?? '')).toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(kTileRadius), border: Border.all(color: cTileBorder, width: 0.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(meetupName.isNotEmpty ? meetupName : 'Meetup #${e['meetup_id'] ?? ''}',
            style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.schedule_rounded, color: cTextTertiary, size: 13),
          const SizedBox(width: 5),
          Text(_fmt((e['start'] ?? '').toString()), style: const TextStyle(color: cTextSecondary, fontSize: 12)),
        ]),
        if ((e['location'] ?? '').toString().isNotEmpty) ...[
          const SizedBox(height: 3),
          Row(children: [
            const Icon(Icons.place_rounded, color: cTextTertiary, size: 13),
            const SizedBox(width: 5),
            Expanded(child: Text(e['location'].toString(), style: const TextStyle(color: cTextSecondary, fontSize: 12))),
          ]),
        ],
        const SizedBox(height: 10),
        Row(children: [
          if (count >= 0)
            Text('$count ${t.rsvpCount}', style: const TextStyle(color: cTextTertiary, fontSize: 12)),
          const Spacer(),
          if (id > 0)
            going
                ? Text(t.rsvpYouGo, style: const TextStyle(color: cGreen, fontSize: 13, fontWeight: FontWeight.w700))
                : SizedBox(
                    height: 34,
                    child: OutlinedButton(
                      onPressed: _busy.contains(id) ? null : () => _doRsvp(id),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: cGreen, width: 1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _busy.contains(id)
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: cGreen, strokeWidth: 2))
                          : Text(t.rsvpGoing, style: const TextStyle(color: cGreen, fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                  ),
        ]),
      ]),
    );
  }
}

// ============================================
//  KURSE & DOZENTEN — Companion-Feature (lesend)
// ============================================
class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _lecturers = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final c = await PortalApiService.getCourses();
    final l = await PortalApiService.getLecturers();
    if (!mounted) return;
    setState(() { _courses = c; _lecturers = l; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: cDark,
        appBar: AppBar(
          backgroundColor: cDark, elevation: 0,
          title: Text(t.paCourses, style: const TextStyle(color: cText, fontWeight: FontWeight.w700, fontSize: 17)),
          bottom: TabBar(
            indicatorColor: cOrange, labelColor: cOrange, unselectedLabelColor: cTextSecondary,
            tabs: [Tab(text: t.crsCourses), Tab(text: t.crsLecturers)],
          ),
        ),
        body: SafeArea(
          child: _loading
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const CircularProgressIndicator(color: cOrange),
                  const SizedBox(height: 12),
                  Text(t.crsLoading, style: const TextStyle(color: cTextSecondary, fontSize: 13)),
                ]))
              : TabBarView(children: [
                  _list(_courses, t, isCourse: true),
                  _list(_lecturers, t, isCourse: false),
                ]),
        ),
      ),
    );
  }

  Widget _list(List<Map<String, dynamic>> items, AppLocalizations t, {required bool isCourse}) {
    if (items.isEmpty) {
      return Center(child: Text(t.crsNone, style: const TextStyle(color: cTextSecondary, fontSize: 14)));
    }
    return RefreshIndicator(
      color: cOrange, backgroundColor: cCard, onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final e = items[i];
          final name = (e['name'] ?? e['title'] ?? '').toString();
          final desc = (e['description'] ?? e['intro'] ?? e['bio'] ?? '').toString();
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(kTileRadius), border: Border.all(color: cTileBorder, width: 0.5)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: cNostr.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)),
                child: Icon(isCourse ? Icons.school_rounded : Icons.person_rounded, color: cNostr, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(desc, maxLines: 3, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: cTextSecondary, fontSize: 12.5, height: 1.4)),
                ],
              ])),
            ]),
          );
        },
      ),
    );
  }
}
