// ============================================
//  Diagnose-Log — Einstellungen
// ============================================
//  Zeigt die persistent gespeicherten Diagnose-Ereignisse (Portal,
//  Admin, Widget, Warnungen, Fehler). Zum Teilen (an dich für die
//  Fehlersuche) und Löschen. Enthält bewusst KEINE Secrets.
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../theme.dart';
import '../services/app_logger.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  String _filter = 'ALLE'; // ALLE | PORTAL | ADMIN | WIDGET | FEHLER

  Color _levelColor(String level) {
    switch (level) {
      case 'ERROR': return cRed;
      case 'WARN': return cOrange;
      default: return cTextSecondary;
    }
  }

  bool _matches(LogEntry e) {
    switch (_filter) {
      case 'PORTAL': return e.tag == 'Portal';
      case 'ADMIN': return e.tag == 'Admin';
      case 'WIDGET': return e.tag.toLowerCase().contains('widget');
      case 'FEHLER': return e.level == 'ERROR' || e.level == 'WARN';
      default: return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Neueste zuerst anzeigen
    final all = AppLogger.entries.reversed.where(_matches).toList();
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        backgroundColor: cDark,
        elevation: 0,
        title: const Text('Diagnose-Log', style: TextStyle(color: cText, fontWeight: FontWeight.w700, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded, color: cTextSecondary, size: 20),
            tooltip: 'Kopieren',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: AppLogger.exportText()));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Log kopiert'), behavior: SnackBarBehavior.floating));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, color: cTextSecondary, size: 20),
            tooltip: 'Teilen',
            onPressed: () {
              final text = AppLogger.exportText();
              if (text.isNotEmpty) Share.share(text, subject: '21Meetup Diagnose-Log');
            },
          ),
        ],
      ),
      body: Column(children: [
        // Filter-Chips
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: ['ALLE', 'PORTAL', 'ADMIN', 'WIDGET', 'FEHLER'].map((f) {
              final sel = _filter == f;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _filter = f),
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: sel ? cOrange.withValues(alpha: 0.2) : cCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sel ? cOrange : cTileBorder, width: 0.5),
                    ),
                    child: Text(f, style: TextStyle(
                      color: sel ? cOrange : cTextSecondary,
                      fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: all.isEmpty
              ? const Center(child: Text('Keine Einträge', style: TextStyle(color: cTextTertiary)))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: all.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    final e = all[i];
                    String two(int n) => n.toString().padLeft(2, '0');
                    final ts = '${two(e.time.hour)}:${two(e.time.minute)}:${two(e.time.second)}';
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: cTileBorder, width: 0.5),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text(ts, style: const TextStyle(color: cTextTertiary, fontSize: 11).copyWith(fontFamily: fontMono)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: _levelColor(e.level).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(e.level, style: TextStyle(color: _levelColor(e.level), fontSize: 9, fontWeight: FontWeight.w800)),
                          ),
                          const SizedBox(width: 6),
                          Text(e.tag, style: const TextStyle(color: cOrange, fontSize: 11, fontWeight: FontWeight.w700)),
                        ]),
                        const SizedBox(height: 4),
                        Text(e.message, style: const TextStyle(color: cText, fontSize: 13)),
                      ]),
                    );
                  },
                ),
        ),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: GestureDetector(
            onTap: () async {
              await AppLogger.clear();
              if (mounted) setState(() {});
            },
            child: Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: cRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cRed.withValues(alpha: 0.3), width: 0.5),
              ),
              child: const Text('Log leeren', style: TextStyle(color: cRed, fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ),
    );
  }
}
