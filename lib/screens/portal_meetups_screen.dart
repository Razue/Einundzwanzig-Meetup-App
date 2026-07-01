// PORTAL — "Meine Meetups verwalten"
// ============================================
// Anmeldung am Einundzwanzig-Portal per Nostr (stateless, kind 22242),
// dann eigene Meetups laden und Termine anlegen.
// Nutzt PortalApiService (loginWithNostr / getMyMeetups / createMeetupEvent).
// ============================================

import 'package:flutter/material.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';
import '../services/portal_api_service.dart';

class PortalMeetupsScreen extends StatefulWidget {
  const PortalMeetupsScreen({super.key});

  @override
  State<PortalMeetupsScreen> createState() => _PortalMeetupsScreenState();
}

class _PortalMeetupsScreenState extends State<PortalMeetupsScreen> {
  bool _checking = true;       // initiale Token-Prüfung
  bool _connected = false;
  bool _loggingIn = false;
  bool _loadingMeetups = false;
  List<PortalMeetup> _meetups = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final has = await PortalApiService.hasToken();
    if (!mounted) return;
    setState(() { _connected = has; _checking = false; });
    if (has) _loadMeetups();
  }

  Future<void> _login() async {
    setState(() => _loggingIn = true);
    final res = await PortalApiService.loginWithNostr();
    if (!mounted) return;
    setState(() => _loggingIn = false);
    if (res.ok) {
      setState(() => _connected = true);
      _loadMeetups();
    } else {
      _snack('${AppLocalizations.of(context).portalLoginFailed}: ${res.error ?? ''}', cRed);
    }
  }

  Future<void> _logout() async {
    await PortalApiService.logout();
    if (!mounted) return;
    setState(() { _connected = false; _meetups = []; });
  }

  Future<void> _loadMeetups() async {
    setState(() => _loadingMeetups = true);
    final list = await PortalApiService.getMyMeetups();
    if (!mounted) return;
    setState(() { _meetups = list; _loadingMeetups = false; });
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        backgroundColor: cDark,
        elevation: 0,
        title: Text(t.portalTitle, style: const TextStyle(color: cText, fontWeight: FontWeight.w700)),
        actions: [
          if (_connected)
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: cTextSecondary),
              tooltip: t.portalLogout,
              onPressed: _logout,
            ),
        ],
      ),
      body: SafeArea(
        child: _checking
            ? const Center(child: CircularProgressIndicator(color: cOrange))
            : _connected
                ? _connectedView(t)
                : _loginView(t),
      ),
    );
  }

  // ── Nicht verbunden ──
  Widget _loginView(AppLocalizations t) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(children: [
      const SizedBox(height: 40),
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(color: cOrange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.hub_rounded, color: cOrange, size: 30),
      ),
      const SizedBox(height: 20),
      Text(t.portalNotConnected, textAlign: TextAlign.center,
          style: const TextStyle(color: cText, fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      Text(t.portalConnectInfo, textAlign: TextAlign.center,
          style: const TextStyle(color: cTextSecondary, fontSize: 14, height: 1.55)),
      const SizedBox(height: 28),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _loggingIn ? null : _login,
          icon: _loggingIn
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.login_rounded, color: Colors.white, size: 18),
          label: Text(_loggingIn ? t.portalConnecting : t.portalConnect,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          style: ElevatedButton.styleFrom(
            backgroundColor: cOrange,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kTileRadius)),
          ),
        ),
      ),
    ]),
  );

  // ── Verbunden ──
  Widget _connectedView(AppLocalizations t) {
    if (_loadingMeetups) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const CircularProgressIndicator(color: cOrange),
        const SizedBox(height: 14),
        Text(t.portalLoadingMeetups, style: const TextStyle(color: cTextSecondary, fontSize: 13)),
      ]));
    }
    return RefreshIndicator(
      color: cOrange, backgroundColor: cCard,
      onRefresh: _loadMeetups,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_meetups.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Column(children: [
                const Icon(Icons.event_busy_rounded, color: cTextTertiary, size: 44),
                const SizedBox(height: 12),
                Text(t.portalNoMeetups, textAlign: TextAlign.center,
                    style: const TextStyle(color: cTextSecondary, fontSize: 14)),
              ]),
            )
          else
            ..._meetups.map((m) => _meetupCard(t, m)),
          const SizedBox(height: 12),
          Center(child: Text(t.portalSource, style: const TextStyle(color: cTextTertiary, fontSize: 11))),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _meetupCard(AppLocalizations t, PortalMeetup m) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: cCard,
      borderRadius: BorderRadius.circular(kTileRadius),
      border: Border.all(color: cTileBorder, width: 0.5),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(m.name, style: const TextStyle(color: cText, fontSize: 16, fontWeight: FontWeight.w700))),
        if (m.isLeader)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: cOrange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
            child: Text(t.portalLeader, style: const TextStyle(color: cOrange, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
      ]),
      const SizedBox(height: 14),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _openEditor(m),
          icon: const Icon(Icons.add_rounded, color: cOrange, size: 18),
          label: Text(t.portalNewEvent, style: const TextStyle(color: cOrange, fontWeight: FontWeight.w700)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: cOrange, width: 1),
            padding: const EdgeInsets.symmetric(vertical: 11),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kTileRadius)),
          ),
        ),
      ),
    ]),
  );

  Future<void> _openEditor(PortalMeetup meetup) async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => _EventEditor(meetup: meetup)),
    );
    if (created == true && mounted) {
      _snack(AppLocalizations.of(context).portalCreatedOk, cGreen);
    }
  }
}

// ============================================
//  EVENT-EDITOR (Termin anlegen)
// ============================================
class _EventEditor extends StatefulWidget {
  final PortalMeetup meetup;
  const _EventEditor({required this.meetup});

  @override
  State<_EventEditor> createState() => _EventEditorState();
}

class _EventEditorState extends State<_EventEditor> {
  final _locationCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  DateTime? _start;
  bool _saving = false;

  @override
  void dispose() {
    _locationCtrl.dispose();
    _descriptionCtrl.dispose();
    _linkCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _start ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_start ?? now),
    );
    if (!mounted) return;
    setState(() {
      _start = DateTime(date.year, date.month, date.day, time?.hour ?? 19, time?.minute ?? 0);
    });
  }

  Future<void> _save() async {
    final t = AppLocalizations.of(context);
    if (_start == null) { _snack(t.portalNeedStart, cRed); return; }
    setState(() => _saving = true);
    // Portal erwartet RFC-3339 in UTC (z.B. 2026-07-21T17:32:28Z)
    final startIso = _start!.toUtc().toIso8601String();
    final res = await PortalApiService.createMeetupEvent(
      meetupId: widget.meetup.id,
      start: startIso,
      location: _emptyToNull(_locationCtrl.text),
      description: _emptyToNull(_descriptionCtrl.text),
      link: _emptyToNull(_linkCtrl.text),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (res.ok) {
      Navigator.pop(context, true);
    } else {
      _snack(res.error ?? 'Fehler', cRed);
    }
  }

  String? _emptyToNull(String s) => s.trim().isEmpty ? null : s.trim();

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  String _fmtStart(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year}  ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        backgroundColor: cDark, elevation: 0,
        title: Text(t.portalEventTitle, style: const TextStyle(color: cText, fontWeight: FontWeight.w700, fontSize: 16)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Meetup-Name (Kontext)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: cCard, borderRadius: BorderRadius.circular(kTileRadius),
                border: Border.all(color: cTileBorder, width: 0.5),
              ),
              child: Row(children: [
                const Icon(Icons.groups_rounded, color: cOrange, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(widget.meetup.name,
                    style: const TextStyle(color: cText, fontSize: 14, fontWeight: FontWeight.w700))),
              ]),
            ),
            // Datum & Uhrzeit
            _label(t.portalFieldStart),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: cCard, borderRadius: BorderRadius.circular(kTileRadius),
                  border: Border.all(color: _start == null ? cTileBorder : cOrange, width: _start == null ? 0.5 : 1),
                ),
                child: Row(children: [
                  Icon(Icons.event_rounded, color: _start == null ? cTextTertiary : cOrange, size: 18),
                  const SizedBox(width: 10),
                  Text(_start == null ? t.portalPickDate : _fmtStart(_start!),
                      style: TextStyle(color: _start == null ? cTextTertiary : cText, fontSize: 15, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            _label(t.portalFieldLocation),
            _input(_locationCtrl, t.portalFieldLocationHint),
            const SizedBox(height: 16),
            _label(t.portalFieldDescription),
            _input(_descriptionCtrl, t.portalFieldDescriptionHint, maxLines: 4),
            const SizedBox(height: 16),
            _label(t.portalFieldLink),
            _input(_linkCtrl, t.portalFieldLinkHint, keyboard: TextInputType.url),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                label: Text(_saving ? t.portalSaving : t.portalSave,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cOrange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kTileRadius)),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ]),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text.toUpperCase(),
        style: const TextStyle(color: cTextTertiary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
  );

  Widget _input(TextEditingController c, String hint, {int maxLines = 1, TextInputType? keyboard}) => TextField(
    controller: c,
    maxLines: maxLines,
    keyboardType: keyboard,
    style: const TextStyle(color: cText, fontSize: 15),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: cTextTertiary, fontSize: 14),
      filled: true, fillColor: cCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(kTileRadius), borderSide: const BorderSide(color: cTileBorder, width: 0.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(kTileRadius), borderSide: const BorderSide(color: cTileBorder, width: 0.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(kTileRadius), borderSide: const BorderSide(color: cOrange, width: 1.5)),
    ),
  );
}
