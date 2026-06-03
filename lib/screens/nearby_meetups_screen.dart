import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';
import '../models/meetup.dart';
import '../services/nearby_meetup_service.dart';
import '../services/geocoding_service.dart';
import 'meetup_details.dart';

enum SearchMode { here, planned }

class NearbyMeetupsScreen extends StatefulWidget {
  const NearbyMeetupsScreen({super.key});
  @override
  State<NearbyMeetupsScreen> createState() => _NearbyMeetupsScreenState();
}

class _NearbyMeetupsScreenState extends State<NearbyMeetupsScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _placeCtrl = TextEditingController();

  SearchMode _mode = SearchMode.here;
  double _radiusKm = 25;

  // Suchzentrum
  double? _centerLat;
  double? _centerLng;
  String _centerLabel = '';
  LocationStatus _locStatus = LocationStatus.ok;

  // Datum
  DateMode _dateMode = DateMode.any;
  DateTime? _dayFrom;
  DateTime? _dayTo;

  // Geocoding
  List<GeoPlace> _placeResults = [];
  bool _searchingPlace = false;
  Timer? _debounce;

  bool _loading = true;
  List<NearbyMeetup> _results = [];

  static const LatLng _fallbackCenter = LatLng(50.5, 9.5);

  @override
  void initState() {
    super.initState();
    _initHere();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _placeCtrl.dispose();
    super.dispose();
  }

  // ── "Hier & jetzt": Standort holen ───────────────────────
  Future<void> _initHere() async {
    setState(() => _loading = true);
    final loc = await NearbyMeetupService.getCurrentLocation();
    if (!mounted) return;
    _locStatus = loc.status;
    if (loc.status == LocationStatus.ok && loc.position != null) {
      _centerLat = loc.position!.latitude;
      _centerLng = loc.position!.longitude;
      _centerLabel = AppLocalizations.of(context).nbCenterHere;
    } else {
      // Ohne Standort: Karte zeigt Mitteleuropa, Nutzer kann auf "Geplant" wechseln
      _centerLat = null;
      _centerLng = null;
    }
    await _runSearch();
  }

  // ── Suche ausführen ──────────────────────────────────────
  Future<void> _runSearch() async {
    if (_centerLat == null || _centerLng == null) {
      setState(() {
        _loading = false;
        _results = [];
      });
      return;
    }
    setState(() => _loading = true);
    final res = await NearbyMeetupService.search(
      centerLat: _centerLat!,
      centerLng: _centerLng!,
      radiusKm: _radiusKm,
      dateMode: _dateMode,
      dayFrom: _dayFrom,
      dayTo: _dayTo,
    );
    if (!mounted) return;
    setState(() {
      _results = res;
      _loading = false;
    });
    _fitMap();
  }

  void _fitMap() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pts = <LatLng>[
        if (_centerLat != null) LatLng(_centerLat!, _centerLng!),
        ..._results.where((n) => n.hasCoords).map((n) => LatLng(n.meetup.lat, n.meetup.lng)),
      ];
      if (pts.isEmpty) return;
      try {
        if (pts.length == 1) {
          _mapController.move(pts.first, 10);
        } else {
          _mapController.fitCamera(CameraFit.coordinates(
            coordinates: pts,
            padding: const EdgeInsets.all(50),
            maxZoom: 12,
          ));
        }
      } catch (_) {}
    });
  }

  // ── Geocoding (Freitext-Ortssuche) ───────────────────────
  void _onPlaceChanged(String q) {
    _debounce?.cancel();
    if (q.trim().length < 2) {
      setState(() => _placeResults = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      setState(() => _searchingPlace = true);
      final res = await GeocodingService.search(q);
      if (!mounted) return;
      setState(() {
        _placeResults = res;
        _searchingPlace = false;
      });
    });
  }

  void _selectPlace(GeoPlace p) {
    FocusScope.of(context).unfocus();
    setState(() {
      _centerLat = p.lat;
      _centerLng = p.lng;
      _centerLabel = p.shortName;
      _placeResults = [];
      _placeCtrl.text = p.shortName;
    });
    _runSearch();
  }

  void _switchMode(SearchMode m) {
    setState(() => _mode = m);
    if (m == SearchMode.here) {
      if (_centerLat == null) {
        _initHere();
      } else {
        _centerLabel = AppLocalizations.of(context).nbCenterHere;
        _runSearch();
      }
    }
    // Bei "Geplant" wartet die App auf Ortswahl durch den Nutzer.
  }

  void _setRadius(double v) => setState(() => _radiusKm = v);

  Future<void> _pickSingleDay() async {
    final d = await _showDatePicker(_dayFrom ?? DateTime.now());
    if (d != null) {
      setState(() {
        _dateMode = DateMode.singleDay;
        _dayFrom = d;
        _dayTo = null;
      });
      _runSearch();
    }
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: (_dayFrom != null && _dayTo != null)
          ? DateTimeRange(start: _dayFrom!, end: _dayTo!)
          : null,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: cOrange, surface: cCard, onSurface: cText),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _dateMode = DateMode.range;
        _dayFrom = picked.start;
        _dayTo = picked.end;
      });
      _runSearch();
    }
  }

  void _setDateAny() {
    setState(() {
      _dateMode = DateMode.any;
      _dayFrom = null;
      _dayTo = null;
    });
    _runSearch();
  }

  Future<DateTime?> _showDatePicker(DateTime initial) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: cOrange, surface: cCard, onSurface: cText),
        ),
        child: child!,
      ),
    );
  }

  void _openDetails(Meetup m) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MeetupDetailsScreen(meetup: m)),
      );

  Future<void> _openInMaps(Meetup m) async {
    final uri = Uri.parse(
        'https://www.openstreetmap.org/?mlat=${m.lat}&mlon=${m.lng}#map=15/${m.lat}/${m.lng}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
        title: Text(t.nbTitle,
            style: const TextStyle(color: cText, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
      ),
      body: Column(
        children: [
          _buildMap(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              children: [
                _buildModeToggle(t),
                const SizedBox(height: 12),
                _buildControls(t),
                const SizedBox(height: 16),
                _buildResultsHeader(t),
                const SizedBox(height: 8),
                ..._buildResults(t),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Karte ────────────────────────────────────────────────
  Widget _buildMap() {
    final markers = <Marker>[
      if (_centerLat != null)
        Marker(
          point: LatLng(_centerLat!, _centerLng!),
          width: 24,
          height: 24,
          child: Container(
            decoration: BoxDecoration(
              color: cCyan,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ..._results.where((n) => n.hasCoords).map((n) => Marker(
            point: LatLng(n.meetup.lat, n.meetup.lng),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () => _openDetails(n.meetup),
              child: Icon(Icons.location_on,
                  color: n.nextEvent != null ? cOrange : cTextSecondary, size: 38),
            ),
          )),
    ];

    return SizedBox(
      height: 230,
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _centerLat != null ? LatLng(_centerLat!, _centerLng!) : _fallbackCenter,
          initialZoom: _centerLat != null ? 9 : 5,
          interactionOptions:
              const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'space.einundzwanzig.meetup',
          ),
          // Radius-Kreis um das Zentrum
          if (_centerLat != null)
            CircleLayer(circles: [
              CircleMarker(
                point: LatLng(_centerLat!, _centerLng!),
                radius: _radiusKm * 1000, // Meter
                useRadiusInMeter: true,
                color: cOrange.withOpacity(0.08),
                borderColor: cOrange.withOpacity(0.4),
                borderStrokeWidth: 1.5,
              ),
            ]),
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }

  // ── Modus-Umschalter ─────────────────────────────────────
  Widget _buildModeToggle(AppLocalizations t) {
    Widget seg(SearchMode m, IconData icon, String label) {
      final active = _mode == m;
      return Expanded(
        child: GestureDetector(
          onTap: () => _switchMode(m),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: active ? cOrange : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 16, color: active ? Colors.black : cTextSecondary),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: active ? Colors.black : cTextSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cTileBorder, width: 0.5),
      ),
      child: Row(children: [
        seg(SearchMode.here, Icons.my_location_rounded, t.nbModeHere),
        seg(SearchMode.planned, Icons.event_rounded, t.nbModePlanned),
      ]),
    );
  }

  // ── Bedien-Panel ─────────────────────────────────────────
  Widget _buildControls(AppLocalizations t) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(kTileRadius),
        border: Border.all(color: cTileBorder, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Ort (nur im Geplant-Modus änderbar)
        if (_mode == SearchMode.planned) ...[
          _buildPlaceSearch(t),
          const SizedBox(height: 14),
        ] else if (_locStatus != LocationStatus.ok) ...[
          _buildLocationHint(t),
          const SizedBox(height: 14),
        ],

        // Umkreis-Regler
        Row(children: [
          const Icon(Icons.radar_rounded, size: 16, color: cTextSecondary),
          const SizedBox(width: 6),
          Text(t.nbRadius, style: const TextStyle(color: cTextSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(t.nbRadiusValue(_radiusKm.round()),
              style: const TextStyle(color: cOrange, fontSize: 14, fontWeight: FontWeight.w800)),
        ]),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: cOrange,
            inactiveTrackColor: cTileBorder,
            thumbColor: cOrange,
            overlayColor: cOrange.withOpacity(0.2),
            trackHeight: 3,
          ),
          child: Slider(
            value: _radiusKm,
            min: 5,
            max: 100,
            divisions: 19,
            onChanged: _setRadius,
            onChangeEnd: (_) => _runSearch(),
          ),
        ),

        const SizedBox(height: 6),
        // Datum
        Row(children: [
          const Icon(Icons.calendar_today_rounded, size: 15, color: cTextSecondary),
          const SizedBox(width: 6),
          Text(t.nbDateSingle, style: const TextStyle(color: cTextSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _dateChip(t.nbDateAny, _dateMode == DateMode.any, _setDateAny),
          _dateChip(
            _dateMode == DateMode.singleDay && _dayFrom != null
                ? DateFormat('dd.MM.yyyy').format(_dayFrom!)
                : t.nbPickDay,
            _dateMode == DateMode.singleDay,
            _pickSingleDay,
            icon: Icons.event,
          ),
          _dateChip(
            _dateMode == DateMode.range && _dayFrom != null && _dayTo != null
                ? t.nbDateFromTo(DateFormat('dd.MM.').format(_dayFrom!), DateFormat('dd.MM.').format(_dayTo!))
                : t.nbPickRange,
            _dateMode == DateMode.range,
            _pickRange,
            icon: Icons.date_range,
          ),
        ]),
      ]),
    );
  }

  Widget _buildPlaceSearch(AppLocalizations t) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(
        controller: _placeCtrl,
        onChanged: _onPlaceChanged,
        style: const TextStyle(color: cText, fontSize: 14),
        decoration: InputDecoration(
          hintText: t.nbSearchPlace,
          hintStyle: const TextStyle(color: cTextTertiary, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: cTextSecondary, size: 20),
          suffixIcon: _searchingPlace
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: cOrange)),
                )
              : null,
          filled: true,
          fillColor: cSurface,
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: cTileBorder, width: 0.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: cTileBorder, width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: cOrange, width: 1),
          ),
        ),
      ),
      // Geocoding-Treffer
      if (_placeResults.isNotEmpty)
        Container(
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            color: cSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: cTileBorder, width: 0.5),
          ),
          child: Column(
            children: _placeResults
                .map((p) => GestureDetector(
                      onTap: () => _selectPlace(p),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: cBorder, width: 0.5)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.place_rounded, size: 16, color: cOrange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(p.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: cText, fontSize: 12)),
                          ),
                        ]),
                      ),
                    ))
                .toList(),
          ),
        ),
      if (_centerLat != null && _centerLabel.isNotEmpty) ...[
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.location_on, size: 14, color: cCyan),
          const SizedBox(width: 4),
          Text(_centerLabel, style: const TextStyle(color: cCyan, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ],
    ]);
  }

  Widget _buildLocationHint(AppLocalizations t) {
    return Row(children: [
      const Icon(Icons.location_off_rounded, size: 16, color: cOrange),
      const SizedBox(width: 8),
      Expanded(
        child: Text(t.nbLocationDeniedSub,
            style: const TextStyle(color: cTextSecondary, fontSize: 11, height: 1.3)),
      ),
      TextButton(
        onPressed: _initHere,
        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
        child: Text(t.nbRetryLocation,
            style: const TextStyle(color: cOrange, fontSize: 11, fontWeight: FontWeight.w700)),
      ),
    ]);
  }

  Widget _dateChip(String label, bool active, VoidCallback onTap, {IconData? icon}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? cOrange : cSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: active ? cOrange : cTileBorder, width: 0.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: active ? Colors.black : cTextSecondary),
            const SizedBox(width: 5),
          ],
          Text(label,
              style: TextStyle(
                  color: active ? Colors.black : cTextSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  // ── Ergebnisse ───────────────────────────────────────────
  Widget _buildResultsHeader(AppLocalizations t) {
    if (_loading || _centerLat == null) return const SizedBox.shrink();
    return Text(t.nbResultsHeader(_results.length),
        style: const TextStyle(color: cTextSecondary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1));
  }

  List<Widget> _buildResults(AppLocalizations t) {
    if (_loading) {
      return [
        const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator(color: cOrange, strokeWidth: 2)),
        ),
      ];
    }
    if (_mode == SearchMode.planned && _centerLat == null) {
      return [_infoBox(Icons.search_rounded, t.nbSearchPlace)];
    }
    if (_results.isEmpty) {
      return [
        _infoBox(Icons.event_busy_rounded, t.nbNoneInRadius, sub: t.nbNoneInRadiusSub),
      ];
    }
    return _results.map((n) => _meetupTile(n, t)).toList();
  }

  Widget _meetupTile(NearbyMeetup n, AppLocalizations t) {
    final ev = n.nextEvent;
    final extra = n.allEvents.length > 1 ? n.allEvents.length - 1 : 0;
    return Container(
      margin: const EdgeInsets.only(bottom: kTileGap),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(kTileRadius),
        border: Border.all(color: cTileBorder, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: cOrange.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.location_on, color: cOrange, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(n.meetup.city, style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)),
              if (n.distanceKm != null) ...[
                const SizedBox(height: 2),
                Text(t.nbKmAway(n.distanceKm!.toStringAsFixed(n.distanceKm! < 10 ? 1 : 0)),
                    style: const TextStyle(color: cTextSecondary, fontSize: 11)),
              ],
            ]),
          ),
          GestureDetector(
            onTap: () => _openInMaps(n.meetup),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: cSurface, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.directions_rounded, color: cCyan, size: 18),
            ),
          ),
        ]),
        // Termin-Info
        if (ev != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: cSurface, borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              const Icon(Icons.schedule_rounded, size: 14, color: cOrange),
              const SizedBox(width: 6),
              Expanded(
                child: Text(_formatEventDate(ev.startTime, t),
                    style: const TextStyle(color: cText, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
          if (ev.location.isNotEmpty && ev.location.toLowerCase() != 'ort unbekannt') ...[
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.place_outlined, size: 13, color: cTextSecondary),
              const SizedBox(width: 5),
              Expanded(
                child: Text(ev.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: cTextSecondary, fontSize: 11)),
              ),
            ]),
          ],
          if (extra > 0) ...[
            const SizedBox(height: 6),
            Text(t.nbMoreDates(extra), style: const TextStyle(color: cOrange, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ] else ...[
          const SizedBox(height: 8),
          Text(t.nbNoDate, style: const TextStyle(color: cTextSecondary, fontSize: 11)),
        ],
        const SizedBox(height: 10),
        // Aktionen
        GestureDetector(
          onTap: () => _openDetails(n.meetup),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: cOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cOrange.withOpacity(0.3), width: 0.5),
            ),
            child: Center(
              child: Text(t.nbDetails,
                  style: const TextStyle(color: cOrange, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _infoBox(IconData icon, String title, {String? sub}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(children: [
        Icon(icon, color: cTextTertiary, size: 52),
        const SizedBox(height: 14),
        Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: cText, fontSize: 14, fontWeight: FontWeight.w700)),
        if (sub != null) ...[
          const SizedBox(height: 6),
          Text(sub,
              textAlign: TextAlign.center,
              style: const TextStyle(color: cTextSecondary, fontSize: 12, height: 1.4)),
        ],
      ]),
    );
  }

  String _formatEventDate(DateTime dt, AppLocalizations t) {
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final tom = now.add(const Duration(days: 1));
    final isTom = dt.year == tom.year && dt.month == tom.month && dt.day == tom.day;
    final time = DateFormat('HH:mm').format(dt);
    if (isToday) return '${t.nbToday}, $time';
    if (isTom) return '${t.nbTomorrow}, $time';
    return DateFormat('EEE, dd.MM.yyyy · HH:mm').format(dt);
  }
}
