// CHAT-BILDSCHIRM
// ============================================
// Zeigt einen Raum des Gruppen-Relays: Nachrichten laden, live nachziehen,
// schreiben. Wer noch nicht Mitglied ist, sieht statt des Eingabefelds einen
// Beitreten-Knopf — die Mitgliedschaft fuehrt das Relay, nicht diese App.
// ============================================

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/chat_service.dart';
import '../services/signing_service.dart';
import '../theme.dart';
import '../widgets/nostr_avatar.dart';

class ChatScreen extends StatefulWidget {
  final ChatRoom room;

  const ChatScreen({super.key, required this.room});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  final List<ChatMessage> _messages = [];
  final Set<String> _seenIds = {};

  bool _loading = true;
  bool _member = false;
  bool _joining = false;
  bool _sending = false;
  String? _myPubkey;

  /// Beendet das offene Abo. MUSS beim Verlassen aufgerufen werden, sonst
  /// bleibt die Relay-Verbindung im Hintergrund bestehen.
  void Function()? _unsubscribe;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _unsubscribe?.call();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _myPubkey = await SigningService.pubkeyHex();
    final msgs = await ChatService.loadMessages(widget.room.h);
    final member = await ChatService.isMember(widget.room.h);
    if (!mounted) return;

    setState(() {
      _messages
        ..clear()
        ..addAll(msgs);
      _seenIds
        ..clear()
        ..addAll(msgs.map((m) => m.id));
      _member = member;
      _loading = false;
    });
    _scrollToEnd();

    // Alles Geladene gilt als gelesen. Der Lesestand liegt nur auf diesem
    // Gerät — Nostr kennt keinen, und er gehört auch nicht ins Netz.
    if (msgs.isNotEmpty) {
      await ChatService.markRead(widget.room.h, msgs.last.createdAt);
    }

    // Ab dem Zeitpunkt der letzten geladenen Nachricht weiterhoeren — sonst
    // kaeme alles Alte ein zweites Mal.
    final since = msgs.isNotEmpty ? msgs.last.createdAt : DateTime.now();
    try {
      _unsubscribe = await ChatService.subscribe(widget.room.h, (m) {
        if (!mounted || _seenIds.contains(m.id)) return;
        setState(() {
          _seenIds.add(m.id);
          _messages.add(m);
          _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        });
        _scrollToEnd();
        // Wer den Raum offen hat, liest mit.
        ChatService.markRead(widget.room.h, m.createdAt);
      }, since: since);
    } catch (_) {
      // Ohne Live-Abo bleibt der Chat lesbar — nur eben nicht von selbst
      // aktuell. Das ist besser als ein Fehlerbildschirm.
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
    });
  }

  Future<void> _join() async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _joining = true);

    final err = await ChatService.join(widget.room.h);
    // Nach dem Beitritt das RELAY fragen statt es anzunehmen: Ein
    // angenommenes 9021 heisst noch nicht, dass die Mitgliederliste schon
    // steht.
    final member =
        err == null ? await ChatService.isMember(widget.room.h) : false;

    if (!mounted) return;
    setState(() {
      _joining = false;
      _member = member;
    });
    if (err != null) {
      messenger.showSnackBar(SnackBar(
          content: Text(t.chatJoinFailed(err)), backgroundColor: cRed));
    }
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sending = true);

    final err = await ChatService.send(widget.room.h, text);

    if (!mounted) return;
    setState(() => _sending = false);
    if (err == null) {
      _inputCtrl.clear();
    } else {
      messenger.showSnackBar(SnackBar(
          content: Text(t.chatSendFailed(err)), backgroundColor: cRed));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        backgroundColor: cDark,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                widget.room.name.isNotEmpty ? widget.room.name : widget.room.h,
                style: const TextStyle(
                    color: cText, fontSize: 15, fontWeight: FontWeight.w700)),
            Text(t.chatRelayHint,
                style: const TextStyle(color: cTextTertiary, fontSize: 10.5)),
          ],
        ),
      ),
      body: Column(children: [
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: cOrange))
              : _messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(t.chatEmpty,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: cTextTertiary,
                                fontSize: 14,
                                height: 1.5)),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) => _bubble(_messages[i]),
                    ),
        ),
        _footer(t),
      ]),
    );
  }

  Widget _bubble(ChatMessage m) {
    final mine = m.pubkey == _myPubkey;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!mine) ...[
            NostrAvatar(
                pubkeyHex: m.pubkey,
                radius: 14,
                // Kürzel aus dem Schlüssel als Rückfall: Ein Anzeigename
                // liegt hier nicht vor, und ein leerer Kreis sagt nichts.
                fallbackText: m.pubkey.substring(0, 2).toUpperCase()),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: mine ? cOrange.withValues(alpha: 0.16) : cCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: mine
                        ? cOrange.withValues(alpha: 0.35)
                        : cTileBorder,
                    width: 0.5),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.content,
                        style: const TextStyle(
                            color: cText, fontSize: 14, height: 1.4)),
                    const SizedBox(height: 4),
                    Text(
                        '${m.createdAt.hour.toString().padLeft(2, '0')}:'
                        '${m.createdAt.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                            color: cTextTertiary, fontSize: 10)),
                  ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer(AppLocalizations t) {
    // Kein Mitglied: Beitreten statt Eingabefeld. Ein Feld anzubieten, dessen
    // Inhalt das Relay ablehnt, waere eine Einladung ins Leere.
    if (!_member) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Text(t.chatJoinHint,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: cTextSecondary, fontSize: 12.5, height: 1.45)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _joining ? null : _join,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cOrange,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kTileRadius)),
                ),
                child: _joining
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.4, color: Colors.black))
                    : Text(t.chatJoin,
                        style:
                            const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ]),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              style: const TextStyle(color: cText, fontSize: 15),
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: t.chatPlaceholder,
                hintStyle:
                    const TextStyle(color: cTextTertiary, fontSize: 14),
                filled: true,
                fillColor: cCard,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide:
                      const BorderSide(color: cTileBorder, width: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide:
                      const BorderSide(color: cTileBorder, width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: cOrange, width: 1.4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            height: 48,
            child: ElevatedButton(
              onPressed: _sending ? null : _send,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: cOrange,
                shape: const CircleBorder(),
              ),
              child: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.send_rounded,
                      color: Colors.black, size: 20),
            ),
          ),
        ]),
      ),
    );
  }
}
