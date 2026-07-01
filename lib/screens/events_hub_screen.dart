// EVENTS-HUB
// ============================================
// Neutrales Auswahlmenü beim Öffnen des Events-Tabs mit drei Bereichen:
//   1. Meetups            -> CalendarScreen (Meetup-Suche & -Liste)
//   2. Veranstaltungskalender -> EventCalendarScreen (Monat/Jahr/Liste, farbig)
//   3. Externe Termine    -> ExternalEventsScreen (nur Nostr-Events, keine Meetups)
// ============================================

import 'package:flutter/material.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';
import '../services/calendar_event_service.dart';
import 'calendar_screen.dart';
import 'event_calendar_screen.dart';

class EventsHubScreen extends StatelessWidget {
  const EventsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        backgroundColor: cDark,
        elevation: 0,
        title: Text(t.hubTitle, style: const TextStyle(color: cText, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _card(
              context,
              icon: Icons.groups_rounded,
              color: cOrange,
              title: t.hubMeetups,
              subtitle: t.hubMeetupsSub,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen())),
            ),
            const SizedBox(height: 14),
            _card(
              context,
              icon: Icons.calendar_month_rounded,
              color: cCyan,
              title: t.hubCalendar,
              subtitle: t.hubCalendarSub,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EventCalendarScreen())),
            ),
            const SizedBox(height: 14),
            _card(
              context,
              icon: Icons.public_rounded,
              color: cGreen,
              title: t.hubExternal,
              subtitle: t.hubExternalSub,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExternalEventsScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [color.withValues(alpha: 0.16), cCard],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(children: [
          Container(
            width: 54, height: 54,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: cText, fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text(subtitle, style: const TextStyle(color: cTextSecondary, fontSize: 12.5, height: 1.35)),
          ])),
          Icon(Icons.chevron_right_rounded, color: color, size: 22),
        ]),
      ),
    );
  }
}

// ============================================
//  EXTERNE TERMINE (nur Nostr-Events, keine Meetups) + eintragen
// ============================================
class ExternalEventsScreen extends StatefulWidget {
  const ExternalEventsScreen({super.key});

  @override
  State<ExternalEventsScreen> createState() => _ExternalEventsScreenState();
}

class _ExternalEventsScreenState extends State<ExternalEventsScreen> {
  bool _loading = true;
  List<NostrCalendarEvent> _events = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await CalendarEventService.fetchEvents();
    if (!mounted) return;
    // Nur kommende, chronologisch
    final now = DateTime.now().subtract(const Duration(days: 1));
    final upcoming = list.where((e) => e.start.isAfter(now)).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    setState(() { _events = upcoming; _loading = false; });
  }

  Future<void> _add() async {
    final published = await Navigator.push<bool>(
      context, MaterialPageRoute(builder: (_) => const EventEditorScreen()),
    );
    if (published == true && mounted) _load();
  }

  String _monthName(AppLocalizations t, int m) {
    switch (m) {
      case 1: return t.calMonth1; case 2: return t.calMonth2; case 3: return t.calMonth3;
      case 4: return t.calMonth4; case 5: return t.calMonth5; case 6: return t.calMonth6;
      case 7: return t.calMonth7; case 8: return t.calMonth8; case 9: return t.calMonth9;
      case 10: return t.calMonth10; case 11: return t.calMonth11; default: return t.calMonth12;
    }
  }

  String _fmtWhen(AppLocalizations t, NostrCalendarEvent e) {
    String two(int n) => n.toString().padLeft(2, '0');
    final d = e.start;
    final date = '${d.day}. ${_monthName(t, d.month)} ${d.year}';
    if (e.allDay) return '$date · ${t.calAllDay}';
    return '$date · ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        backgroundColor: cDark, elevation: 0,
        title: Text(t.extTitle, style: const TextStyle(color: cText, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: cTextSecondary), onPressed: _loading ? null : _load),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: cGreen,
        onPressed: _add,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(t.extAdd, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: _loading
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                const CircularProgressIndicator(color: cGreen),
                const SizedBox(height: 14),
                Text(t.extLoading, style: const TextStyle(color: cTextSecondary, fontSize: 13)),
              ]))
            : RefreshIndicator(
                color: cGreen, backgroundColor: cCard,
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  children: [
                    // Info
                    Container(
                      padding: const EdgeInsets.all(13),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: cGreen.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(kTileRadius),
                        border: Border.all(color: cGreen.withValues(alpha: 0.3), width: 0.5),
                      ),
                      child: Row(children: [
                        const Icon(Icons.info_outline_rounded, color: cGreen, size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: Text(t.extIntro, style: const TextStyle(color: cTextSecondary, fontSize: 12, height: 1.45))),
                      ]),
                    ),
                    if (_events.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Column(children: [
                          const Icon(Icons.event_busy_rounded, color: cTextTertiary, size: 44),
                          const SizedBox(height: 12),
                          Text(t.extNone, textAlign: TextAlign.center,
                              style: const TextStyle(color: cTextSecondary, fontSize: 14)),
                        ]),
                      )
                    else
                      ..._events.map((e) => _eventCard(t, e)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _eventCard(AppLocalizations t, NostrCalendarEvent e) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: cCard, borderRadius: BorderRadius.circular(kTileRadius),
      border: Border.all(color: cTileBorder, width: 0.5),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 8, height: 8, decoration: const BoxDecoration(color: cNostr, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(e.title, style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700))),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        const Icon(Icons.schedule_rounded, color: cTextTertiary, size: 13),
        const SizedBox(width: 5),
        Text(_fmtWhen(t, e), style: const TextStyle(color: cTextSecondary, fontSize: 12)),
      ]),
      if (e.location.isNotEmpty) ...[
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.place_rounded, color: cTextTertiary, size: 13),
          const SizedBox(width: 5),
          Expanded(child: Text(e.location, style: const TextStyle(color: cTextSecondary, fontSize: 12))),
        ]),
      ],
      if (e.description.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(e.description, maxLines: 3, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: cTextSecondary, fontSize: 13, height: 1.4)),
      ],
    ]),
  );
}
