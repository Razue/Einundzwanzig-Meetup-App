import 'package:flutter/material.dart';
import '../models/meetup.dart';
import '../models/user.dart';
import '../services/meetup_service.dart'; // <--- Service nutzen
import '../theme.dart';
import '../l10n/app_localizations.dart';
import '../services/app_logger.dart';

class MeetupSelectionScreen extends StatefulWidget {
  const MeetupSelectionScreen({super.key});

  @override
  State<MeetupSelectionScreen> createState() => _MeetupSelectionScreenState();
}

class _MeetupSelectionScreenState extends State<MeetupSelectionScreen> {
  List<Meetup> _meetups = [];
  List<Meetup> _filteredMeetups = [];
  bool _isLoading = true;
  // MULTI-SELECT: mehrere gleichwertige Favoriten. Wir merken uns die
  // Stadtnamen (wie bisher gespeichert), damit nichts an der Persistenz bricht.
  final Set<String> _selected = {};
  bool _saving = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterMeetups);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterMeetups() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredMeetups = _meetups;
      } else {
        _filteredMeetups = _meetups.where((meetup) =>
          meetup.city.toLowerCase().contains(query) ||
          meetup.country.toLowerCase().contains(query)
        ).toList();
      }
    });
  }

  void _loadData() async {
    // Bestehende Favoriten vorauswaehlen, damit der Screen auch zum
    // spaeteren Bearbeiten/Ergaenzen dient (nicht nur Erst-Setup).
    final user = await UserProfile.load();
    final list = await MeetupService.fetchMeetups();
    if (!mounted) return;
    setState(() {
      _meetups = list;
      _filteredMeetups = list;
      _selected
        ..clear()
        ..addAll(user.favoriteMeetupIds);
      _isLoading = false;
    });
  }

  Future<void> _saveAndClose() async {
    setState(() => _saving = true);
    final user = await UserProfile.load();
    final favs = _selected.toList();
    user.favoriteMeetupIds = favs;
    // homeMeetupId bleibt als Widget-Routing-Ziel erhalten: erster Favorit,
    // sonst leer. Alle Favoriten sind gleichwertig; das ist nur der Anker
    // fuers Homescreen-Widget.
    user.homeMeetupId = favs.isNotEmpty ? favs.first : '';
    await user.save();
    AppLogger.debug('App', '[DEBUG] Favoriten gespeichert: ${favs.length} (${favs.join(", ")})');
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        title: Text(t.msSelectMeetup),
        actions: [
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text('${_selected.length}',
                    style: const TextStyle(color: cOrange, fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            ),
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator(color: cOrange))
        : Column(
            children: [
              // Suchfeld
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: t.msSearchMeetup,
                    prefixIcon: const Icon(Icons.search, color: cOrange),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: cTextTertiary),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                  ),
                ),
              ),
              // Hinweis
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Row(children: [
                  const Icon(Icons.star_rounded, color: cOrange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(t.msFavoritesHint,
                      style: const TextStyle(color: cTextSecondary, fontSize: 12.5))),
                ]),
              ),
              // Meetup-Liste (Multi-Select)
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _filteredMeetups.length,
                  itemBuilder: (context, index) {
                    final meetup = _filteredMeetups[index];
                    final active = _selected.contains(meetup.city);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: cCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: active ? cOrange : cBorder, width: active ? 1.4 : 1),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            // TOGGLE statt sofort speichern & schliessen.
                            setState(() {
                              if (active) {
                                _selected.remove(meetup.city);
                              } else {
                                _selected.add(meetup.city);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: cOrange.withValues(alpha: active ? 0.22 : 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.location_on,
                                    color: cOrange,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        meetup.city.toUpperCase(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      // Gruppenname nur zeigen, wenn er WIRKLICH
                                      // unterscheidet — sonst nur Doppelung.
                                      if (meetup.name.isNotEmpty &&
                                          meetup.name.toLowerCase() != meetup.city.toLowerCase())
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Text(meetup.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(color: cTextTertiary, fontSize: 11.5)),
                                        ),
                                    ],
                                  ),
                                ),
                                // Checkbox-Optik statt Pfeil
                                // STERN = als Favorit/Home-Meetup markiert.
                                Icon(
                                  active ? Icons.star_rounded : Icons.star_outline_rounded,
                                  color: active ? cOrange : cTextTertiary,
                                  size: 26,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Fertig-Button
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _saveAndClose,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cOrange,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _saving
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                          : Text(
                              _selected.isEmpty ? t.msSaveNone : t.msSaveFavorites(_selected.length),
                              style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w800),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
