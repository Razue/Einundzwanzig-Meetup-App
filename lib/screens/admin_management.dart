// ============================================
// ADMIN MANAGEMENT SCREEN v3 (WEB OF TRUST)
// Dezentrales Peer-to-Peer Vouching (Ritterschlag)
// ============================================

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import '../services/admin_registry.dart';
import '../services/nostr_service.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';

class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
  List<AdminEntry> _admins = [];
  bool _isLoading = true;
  bool _isPublishing = false;
  bool _isRefreshing = false;
  Duration? _cacheAge;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _loadAdmins();
    _autoSyncMyVouches(); // beim Öffnen meine Bürgschaften mit Relays abgleichen
  }

  /// Gleicht beim Öffnen still meine publizierte Bürgschafts-Liste mit den
  /// Relays ab, damit die lokale Liste nie veraltet (und nach Neuinstallation
  /// automatisch zurückkommt).
  Future<void> _autoSyncMyVouches() async {
    try {
      final count = await AdminRegistry.recoverMyVouchesFromRelays();
      if (count >= 0 && mounted) {
        await _loadAdmins();
      }
    } catch (_) {
      // Stilles Scheitern — manueller Button bleibt als Fallback
    }
  }

  Future<void> _loadAdmins() async {
    // Persönliche Bürgschaften anzeigen (derselbe Topf, der publiziert
    // und wiederhergestellt wird) — nicht der Netzwerk-Cache aller Admins.
    final admins = await AdminRegistry.getMyVouches();
    final age = await AdminRegistry.cacheAge();
    if (mounted) {
      setState(() {
        _admins = admins;
        _cacheAge = age;
        _isLoading = false;
      });
    }
  }

  // --- QR SCANNER FÜR NPUB ---
  Future<String?> _scanNpub() async {
    return await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const _NpubScannerScreen()),
    );
  }

  // --- ADMIN HINZUFÜGEN (DER RITTERSCHLAG) ---
  void _addAdmin() {
    final npubController = TextEditingController();
    final meetupController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cCard,
        title: Row(
          children: [
            const Icon(Icons.shield, color: cPurple),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context).admCoAdminKnight, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).admVouchNewExplain,
                style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 16),
              
              // npub Feld mit Scan-Button
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: npubController,
                      style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 11),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).wotNpubRequired,
                        labelStyle: const TextStyle(color: Colors.grey),
                        hintText: "npub1...",
                        filled: true, fillColor: cDark,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(color: cCyan.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                    child: IconButton(
                      icon: const Icon(Icons.qr_code_scanner, color: cCyan),
                      onPressed: () async {
                        final scannedNpub = await _scanNpub();
                        if (scannedNpub != null && mounted) {
                          setState(() {
                            npubController.text = scannedNpub;
                          });
                        }
                      },
                    ),
                  )
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: meetupController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).wotMeetupExample,
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true, fillColor: cDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).wotNameAlias,
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true, fillColor: cDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).admCancel, style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: cPurple, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await AdminRegistry.addVouch(AdminEntry(
                  npub: npubController.text.trim(),
                  meetup: meetupController.text.trim(),
                  name: nameController.text.trim(),
                ));
                if (mounted) {
                  Navigator.pop(context);
                  _loadAdmins();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context).admCoAdminAdded), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("❌ $e"), backgroundColor: Colors.red),
                );
              }
            },
            child: Text(AppLocalizations.of(context).wotVouchVerb, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- ADMIN ENTFERNEN ---
  void _removeAdmin(AdminEntry admin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cCard,
        title: Text(AppLocalizations.of(context).admRevokeTrust, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text(
          AppLocalizations.of(context).admRevokeTrustBody(admin.name.isNotEmpty ? admin.name : NostrService.shortenNpub(admin.npub), admin.meetup) +
          AppLocalizations.of(context).admMustRepublish,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).admCancel, style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await AdminRegistry.removeVouch(admin.npub);
              if (mounted) {
                Navigator.pop(context);
                _loadAdmins();
              }
            },
            child: Text(AppLocalizations.of(context).admRemove, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- AUF RELAYS PUBLISHEN (Der eigentliche Beweis) ---
  void _publishToRelays() async {
    setState(() {
      _isPublishing = true;
      _statusMessage = AppLocalizations.of(context).admSigningSending;
    });

    try {
      final result = await AdminRegistry.createAndPublishAdminListEvent();
      final data = jsonDecode(result);
      final sentTo = data['sent_to'] ?? 0;

      setState(() {
        _isPublishing = false;
        _statusMessage = AppLocalizations.of(context).admWotLive(sentTo);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).admDelegationSigned),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isPublishing = false;
        _statusMessage = AppLocalizations.of(context).admErrorEmoji(e.toString());
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- VON RELAYS LADEN ---
  void _refreshFromRelays() async {
    setState(() {
      _isRefreshing = true;
      _statusMessage = AppLocalizations.of(context).admSyncingWot;
    });

    try {
      final count = await AdminRegistry.forceRefresh();
      if (count >= 0) {
        await _loadAdmins();
        setState(() {
          _isRefreshing = false;
          _statusMessage = AppLocalizations.of(context).admWotCurrent(count);
        });
      } else {
        setState(() {
          _isRefreshing = false;
          _statusMessage = AppLocalizations.of(context).admNoNewUpdates;
        });
      }
    } catch (e) {
      setState(() {
        _isRefreshing = false;
        _statusMessage = '❌ Sync fehlgeschlagen: $e';
      });
    }
  }

  // --- MEINE BÜRGSCHAFTEN VON RELAYS WIEDERHERSTELLEN ---
  void _recoverMyVouches() async {
    setState(() {
      _isRefreshing = true;
      _statusMessage = AppLocalizations.of(context).admRestoringVouches;
    });
    try {
      final count = await AdminRegistry.recoverMyVouchesFromRelays();
      if (count >= 0) {
        await _loadAdmins();
        setState(() {
          _isRefreshing = false;
          _statusMessage = count == 0
              ? AppLocalizations.of(context).admNoVouchesFound
              : AppLocalizations.of(context).admVouchesRestored(count);
        });
      } else {
        setState(() {
          _isRefreshing = false;
          _statusMessage = AppLocalizations.of(context).admNoRelayReachable;
        });
      }
    } catch (e) {
      setState(() {
        _isRefreshing = false;
        _statusMessage = '❌ Wiederherstellung fehlgeschlagen: $e';
      });
    }
  }

  // --- NOTAUSGANG: ALLE BÜRGSCHAFTEN WIDERRUFEN ---
  void _revokeAllVouches() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cCard,
        title: Text(AppLocalizations.of(context).wotRevokeAllTitle,
            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(
          AppLocalizations.of(context).wotRevokeAllBody +
          AppLocalizations.of(context).wotVouchesSignedOnNostr +
          AppLocalizations.of(context).wotVisibleLocally +
          AppLocalizations.of(context).wotCantResolveOld,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).admCancel, style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _isPublishing = true;
                _statusMessage = AppLocalizations.of(context).admRevokingAll;
              });
              try {
                await AdminRegistry.revokeAllVouches();
                await _loadAdmins();
                setState(() {
                  _isPublishing = false;
                  _statusMessage = AppLocalizations.of(context).admAllVouchesRevoked;
                });
              } catch (e) {
                setState(() {
                  _isPublishing = false;
                  _statusMessage = '❌ Widerruf fehlgeschlagen: $e';
                });
              }
            },
            child: Text(AppLocalizations.of(context).wotRevokeAll, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).admMyWebOfTrust),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: cCyan))
                : const Icon(Icons.sync, color: cCyan),
            tooltip: AppLocalizations.of(context).admSyncWot,
            onPressed: _isRefreshing ? null : _refreshFromRelays,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addAdmin,
        backgroundColor: cPurple,
        icon: const Icon(Icons.shield, color: Colors.white),
        label: Text(AppLocalizations.of(context).admKnighthood, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: cPurple))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Info & Status Header
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: cCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cPurple.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.hub, color: cPurple, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context).admMyDelegations,
                                  style: TextStyle(color: cPurple, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppLocalizations.of(context).admVouchedCount(_admins.length),
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_statusMessage.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _statusMessage.startsWith('✅') ? Colors.green.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _statusMessage,
                            style: TextStyle(
                              color: _statusMessage.startsWith('✅') ? Colors.green
                                  : _statusMessage.startsWith('❌') ? Colors.redAccent
                                  : Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // PUBLISH Button (Immer sichtbar — auch bei leerer Liste für Revocation)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _isPublishing ? null : _publishToRelays,
                    icon: _isPublishing
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.satellite_alt, color: Colors.white),
                    label: Text(
                      _isPublishing 
                          ? AppLocalizations.of(context).wotSigningPublishing 
                          : _admins.isEmpty 
                              ? AppLocalizations.of(context).wotPublishRevocation
                              : AppLocalizations.of(context).wotPublishNostr,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _admins.isEmpty ? Colors.red.shade700 : cOrange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _admins.isEmpty
                      ? AppLocalizations.of(context).admPublishEmptyRevoke
                      : AppLocalizations.of(context).admNetworkLearnsKnight,
                  style: const TextStyle(color: Colors.grey, fontSize: 11, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // WIEDERHERSTELLEN + NOTAUSGANG
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isRefreshing ? null : _recoverMyVouches,
                        icon: const Icon(Icons.cloud_download_outlined, size: 18),
                        label: Text(AppLocalizations.of(context).wotRestore, style: const TextStyle(fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: cCyan,
                          side: const BorderSide(color: cCyan),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isPublishing ? null : _revokeAllVouches,
                        icon: const Icon(Icons.block, size: 18),
                        label: Text(AppLocalizations.of(context).wotRevokeAll, style: const TextStyle(fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  AppLocalizations.of(context).admRestoreExplain +
                  AppLocalizations.of(context).admRestoreListBack,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 10, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Admin-Liste
                if (_admins.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Column(
                      children: [
                        const Icon(Icons.group_off, size: 64, color: Colors.white12),
                        const SizedBox(height: 16),
                        Text(AppLocalizations.of(context).admNobodyDelegated, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                        const SizedBox(height: 12),
                        Text(
                          AppLocalizations.of(context).admTapKnighthood,
                          style: const TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ..._admins.map((admin) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: cCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cPurple.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.verified_user, color: cPurple, size: 24),
                      ),
                      title: Text(
                        admin.name.isNotEmpty ? admin.name : NostrService.shortenNpub(admin.npub),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          if (admin.meetup.isNotEmpty)
                            Text("📍 ${admin.meetup}", style: const TextStyle(color: cOrange, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(
                            NostrService.shortenNpub(admin.npub, chars: 8),
                            style: const TextStyle(color: Colors.grey, fontFamily: 'monospace', fontSize: 11),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 22),
                        tooltip: AppLocalizations.of(context).admRevokeTrustShort,
                        onPressed: () => _removeAdmin(admin),
                      ),
                    ),
                  )),

                const SizedBox(height: 100), // Platz für FAB
              ],
            ),
    );
  }
}

// ============================================
// HELPER SCREEN: NPUB QR SCANNER
// ============================================
class _NpubScannerScreen extends StatefulWidget {
  const _NpubScannerScreen();

  @override
  State<_NpubScannerScreen> createState() => _NpubScannerScreenState();
}

class _NpubScannerScreenState extends State<_NpubScannerScreen> {
  bool _isScanned = false;

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;
    for (final barcode in capture.barcodes) {
      String? code = barcode.rawValue;
      if (code != null) {
        // Bereinigen (oft ist ein "nostr:" davor)
        code = code.trim().toLowerCase();
        if (code.startsWith('nostr:')) {
          code = code.replaceFirst('nostr:', '');
        }

        // Prüfen, ob es ein valider npub ist
        if (code.startsWith('npub1') && code.length > 50) {
          setState(() => _isScanned = true);
          Navigator.pop(context, code);
          return;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text(AppLocalizations.of(context).wotScanNpub), backgroundColor: Colors.transparent, elevation: 0),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),
          Positioned(
            bottom: 60, left: 40, right: 40,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8), 
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cPurple),
              ),
              child: Text(
                AppLocalizations.of(context).admScanNewOrg,
                style: TextStyle(color: Colors.white, fontSize: 14, height: 1.4), 
                textAlign: TextAlign.center
              ),
            ),
          ),
        ],
      ),
    );
  }
}


