// ORTSAUSWAHL AUF DER KARTE
// ============================================
// Warum es das braucht: Ein Event wird oft Wochen vorher angelegt — vom
// Sofa aus, nicht am Veranstaltungsort. "Aktuellen Standort uebernehmen"
// haette dann die Koordinaten des Wohnzimmers hinterlegt, und die
// Ortspruefung beim Badge-Ausgeben haette am falschen Punkt gemessen.
//
// Hier wird der Punkt gesetzt, an dem das Event STATTFINDET.
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../l10n/app_localizations.dart';
import '../services/meetup_location_service.dart';
import '../theme.dart';

class LocationPickerScreen extends StatefulWidget {
  /// Vorbelegung, wenn schon ein Punkt gesetzt war.
  final double? initialLat;
  final double? initialLng;

  const LocationPickerScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _mapController = MapController();

  /// Mitte von Deutschland — nur der Startblick, wenn nichts bekannt ist.
  static const LatLng _fallbackCenter = LatLng(51.1657, 10.4515);

  LatLng? _picked;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null &&
        widget.initialLng != null &&
        (widget.initialLat != 0 || widget.initialLng != 0)) {
      _picked = LatLng(widget.initialLat!, widget.initialLng!);
    }
  }

  /// Zum eigenen Standort springen — als Startpunkt der Suche, nicht als
  /// Auswahl. Der Punkt wird bewusst NICHT gesetzt: Wer in Frankfurt sitzt
  /// und ein Event in Hamburg anlegt, soll nicht versehentlich Frankfurt
  /// hinterlegen.
  Future<void> _jumpToMe() async {
    setState(() => _locating = true);
    final res = await MeetupLocationService.resolveLocation();
    if (!mounted) return;
    setState(() => _locating = false);
    if (res.lat == 0 && res.lng == 0) return;
    _mapController.move(LatLng(res.lat, res.lng), 13);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final picked = _picked;

    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        backgroundColor: cDark,
        elevation: 0,
        title: Text(t.locPickTitle,
            style: const TextStyle(
                color: cText, fontWeight: FontWeight.w700, fontSize: 16)),
        actions: [
          IconButton(
            icon: _locating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: cOrange))
                : const Icon(Icons.my_location_rounded, color: cTextSecondary),
            tooltip: t.locPickJumpToMe,
            onPressed: _locating ? null : _jumpToMe,
          ),
        ],
      ),
      body: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: cCard,
          child: Text(
            picked == null ? t.locPickHint : t.locPickHintDone,
            style: const TextStyle(
                color: cTextSecondary, fontSize: 12.5, height: 1.45),
          ),
        ),
        Expanded(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: picked ?? _fallbackCenter,
              initialZoom: picked != null ? 15 : 5,
              interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
              onTap: (_, point) => setState(() => _picked = point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'space.einundzwanzig.meetup',
              ),
              if (picked != null)
                MarkerLayer(markers: [
                  Marker(
                    point: picked,
                    width: 44,
                    height: 44,
                    // Die Spitze der Nadel sitzt unten — sonst zeigt sie
                    // neben den Punkt, den man angetippt hat.
                    alignment: Alignment.topCenter,
                    child: const Icon(Icons.location_on_rounded,
                        color: cOrange, size: 44),
                  ),
                ]),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              if (picked != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    '${picked.latitude.toStringAsFixed(5)}, ${picked.longitude.toStringAsFixed(5)}',
                    style: const TextStyle(
                        color: cTextSecondary,
                        fontSize: 13,
                        fontFamily: 'monospace'),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: picked == null
                      ? null
                      : () => Navigator.pop(context, picked),
                  icon: const Icon(Icons.check_rounded,
                      color: Colors.black, size: 18),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cOrange,
                    disabledBackgroundColor: cSurface,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(kTileRadius)),
                  ),
                  label: Text(t.locPickConfirm,
                      style: TextStyle(
                          color: picked == null ? cTextTertiary : Colors.black,
                          fontWeight: FontWeight.w800)),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
