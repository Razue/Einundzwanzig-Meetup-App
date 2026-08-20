// MEINE TERMINE
// ============================================
// Alles, wofuer man zugesagt hat — mit dem Weg in den jeweiligen Chat und
// dem Hinweis, ob dort etwas Neues steht.
//
// Warum ein eigener Bildschirm und nicht der Kalender: Im Kalender steht
// ALLES, hier nur das, wo man hingeht. Das sind zwei verschiedene Fragen —
// "was gibt es?" und "was habe ich vor?" — und die zweite beantwortet sich
// schlecht in einer Liste mit hundert Terminen.
// ============================================

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/calendar_event.dart';
import '../services/calendar_event_service.dart';
import '../services/event_chat_service.dart';
import '../theme.dart';
import 'chat_screen.dart';

/// Ein anstehender Meetup-Termin aus den Favoriten.
class MyMeetupDate {
  /// Gespeicherter Favorit (Portal-ID) — Schluessel fuer den Chat.
  final String favKey;
  final String label;
  final CalendarEvent event;

  /// Teilnehmerzahl laut Portal, -1 wenn unbekannt.
  final int attendees;

  const MyMeetupDate({
    required this.favKey,
    required this.label,
    required this.event,
    this.attendees = -1,
  });
}

class MyEventsScreen extends StatefulWidget {
  /// Zugesagte Veranstaltungen, bereits nach Datum sortiert.
  final List<NostrCalendarEvent> events;

  /// Naechste Termine der Favoriten-Meetups.
  final List<MyMeetupDate> meetupDates;

  /// Oeffnet den Chatraum eines Meetups. Kommt von aussen, weil die Suche
  /// ueber das Gruppen-Relay laeuft und das Dashboard sie ohnehin kennt.
  final Future<void> Function(String favKey, String label) onOpenMeetupChat;

  const MyEventsScreen({
    super.key,
    required this.events,
    required this.meetupDates,
    required this.onOpenMeetupChat,
  });

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
  Map<String, int> _unread = {};

  @override
  void initState() {
    super.initState();
    _loadUnread();
  }

  Future<void> _loadUnread() async {
    if (widget.events.isEmpty) return;
    final counts = await EventChatService.unreadCounts(
        widget.events.map((e) => e.address).toList());
    if (mounted) setState(() => _unread = counts);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        backgroundColor: cDark,
        elevation: 0,
        title: Text(t.eventChatsTitle,
            style: const TextStyle(
                color: cText, fontWeight: FontWeight.w700, fontSize: 16)),
      ),
      // Ziehen zum Aktualisieren — hier holt es die ungelesenen Beitraege
      // neu. Auch ueber dem Leer-Hinweis, denn gerade dort will man es
      // versuchen.
      body: RefreshIndicator(
        onRefresh: _loadUnread,
        color: cOrange,
        backgroundColor: cCard,
        child: widget.events.isEmpty && widget.meetupDates.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(t.eventChatsEmpty,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: cTextTertiary, fontSize: 14, height: 1.55)),
              ),
                  ),
                ),
              ],
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                // Meetups zuerst: Das sind die regelmaessigen Termine, zu
                // denen man ohnehin geht. Veranstaltungen sind die Ausnahme
                // und stehen darunter.
                if (widget.meetupDates.isNotEmpty) ...[
                  _sectionLabel(t.eventChatsMeetups),
                  ...widget.meetupDates.map((m) => _meetupCard(t, m)),
                ],
                if (widget.events.isNotEmpty) ...[
                  _sectionLabel(t.eventChatsEvents),
                  ...widget.events.map((e) => _card(t, e)),
                ],
              ],
            ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 8, 2, 10),
        child: Text(text.toUpperCase(),
            style: const TextStyle(
                color: cTextTertiary,
                fontSize: 11,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w800)),
      );

  /// Ein Meetup-Termin, fuer den man im Portal zugesagt hat.
  Widget _meetupCard(AppLocalizations t, MyMeetupDate m) {
    final d = m.event.startTime;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cCard,
          borderRadius: BorderRadius.circular(kTileRadius),
          border: Border.all(color: cTileBorder, width: 0.5),
        ),
        child: Row(children: [
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: cText,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 5),
                  Row(children: [
                    const Icon(Icons.event_rounded,
                        color: cTextTertiary, size: 13),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                          '${d.day}.${d.month}.${d.year} · '
                          '${d.hour.toString().padLeft(2, '0')}:'
                          '${d.minute.toString().padLeft(2, '0')}'
                          // Teilnehmerzahl nur, wenn das Portal sie kennt —
                          // "0 Teilnehmer" bei fehlender Angabe waere eine
                          // falsche Auskunft.
                          '${m.attendees >= 0 ? ' · ${t.rsvpAttendees(m.attendees)}' : ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: cTextTertiary, fontSize: 12)),
                    ),
                  ]),
                ]),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => widget.onOpenMeetupChat(m.favKey, m.label),
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: cNostr.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.forum_rounded, color: cNostr, size: 19),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _card(AppLocalizations t, NostrCalendarEvent event) {
    final unread = _unread[event.address] ?? 0;
    final days = event.start.difference(DateTime.now()).inDays;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen.event(
                eventAddress: event.address,
                eventAuthor: event.pubkey,
                title: event.title,
              ),
            ),
          );
          // Zurueck aus dem Chat: Der Lesestand hat sich geaendert, also neu
          // zaehlen — sonst bliebe der Punkt stehen.
          if (mounted) _loadUnread();
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cCard,
            borderRadius: BorderRadius.circular(kTileRadius),
            border: Border.all(
                color: unread > 0
                    ? cNostr.withValues(alpha: 0.5)
                    : cTileBorder,
                width: 0.5),
          ),
          child: Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: cText,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            height: 1.25)),
                    const SizedBox(height: 5),
                    Row(children: [
                      Icon(Icons.event_rounded,
                          color: days <= 0
                              ? cOrange
                              : days <= 3
                                  ? cOrange.withValues(alpha: 0.8)
                                  : cTextTertiary,
                          size: 13),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                            '${event.start.day}.${event.start.month}.${event.start.year}'
                            '${event.location.isEmpty ? '' : ' · ${event.location}'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: cTextTertiary, fontSize: 12)),
                      ),
                    ]),
                  ]),
            ),
            const SizedBox(width: 10),
            // Die Sprechblase traegt den Zaehler. Ohne Neues bleibt sie
            // blass — sichtbar genug, um den Weg zu zeigen, ruhig genug, um
            // nicht nach Aufmerksamkeit zu rufen.
            Stack(clipBehavior: Clip.none, children: [
              Icon(Icons.forum_rounded,
                  color: unread > 0 ? cNostr : cTextTertiary, size: 22),
              if (unread > 0)
                Positioned(
                  right: -6,
                  top: -5,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    constraints: const BoxConstraints(minWidth: 14),
                    decoration: BoxDecoration(
                      color: cOrange,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(unread > 99 ? '99+' : '$unread',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.black,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            height: 1.3)),
                  ),
                ),
            ]),
          ]),
        ),
      ),
    );
  }
}
