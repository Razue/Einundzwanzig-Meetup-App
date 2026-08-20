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
import '../services/calendar_event_service.dart';
import '../services/event_chat_service.dart';
import '../theme.dart';
import 'chat_screen.dart';

class MyEventsScreen extends StatefulWidget {
  /// Zugesagte Termine, bereits nach Datum sortiert.
  final List<NostrCalendarEvent> events;

  const MyEventsScreen({super.key, required this.events});

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
      body: widget.events.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(t.eventChatsEmpty,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: cTextTertiary, fontSize: 14, height: 1.55)),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: widget.events.length,
              itemBuilder: (_, i) => _card(t, widget.events[i]),
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
