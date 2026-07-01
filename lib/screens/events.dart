import 'package:flutter/material.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';
import '../models/meetup.dart';
import '../services/meetup_service.dart';
import 'meetup_details.dart';
import 'event_calendar_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  List<Meetup> _meetups = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  List<Meetup> _filteredMeetups = [];

  @override
  void initState() {
    super.initState();
    _loadMeetups();
    _searchController.addListener(_filterMeetups);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadMeetups() async {
    final list = await MeetupService.fetchMeetups();
    setState(() {
      _meetups = list;
      _filteredMeetups = list;
      _isLoading = false;
    });
  }

  void _filterMeetups() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredMeetups = _meetups;
      } else {
        _filteredMeetups = _meetups
            .where((meetup) =>
                meetup.city.toLowerCase().contains(query) ||
                meetup.country.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).evDatesEvents),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: cOrange))
          : Column(
              children: [
                // Info Header
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cCyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.event, color: cCyan, size: 32),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context).evUpcomingEvents,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context).evIntro,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),

                // Veranstaltungskalender-Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EventCalendarScreen())),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: [cCyan.withValues(alpha: 0.18), cCard],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cCyan.withValues(alpha: 0.4)),
                      ),
                      child: Row(children: [
                        Container(
                          width: 46, height: 46,
                          decoration: BoxDecoration(color: cCyan.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.calendar_month_rounded, color: cCyan, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(AppLocalizations.of(context).evCalendarButton,
                              style: const TextStyle(color: cText, fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(AppLocalizations.of(context).evCalendarButtonSub,
                              style: const TextStyle(color: cTextSecondary, fontSize: 12)),
                        ])),
                        const Icon(Icons.chevron_right_rounded, color: cCyan, size: 20),
                      ]),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Suchfeld
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context).evSearchCityCountry,
                      prefixIcon: const Icon(Icons.search, color: cCyan),
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

                const SizedBox(height: 20),

                // Meetup Liste
                Expanded(
                  child: _filteredMeetups.isEmpty
                      ? Center(
                          child: Text(
                            AppLocalizations.of(context).evNoMeetupsFound,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _filteredMeetups.length,
                          itemBuilder: (context, index) {
                            final meetup = _filteredMeetups[index];
                            return _buildEventCard(meetup);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildEventCard(Meetup meetup) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MeetupDetailsScreen(meetup: meetup),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon Container
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: cCyan,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Meetup Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meetup.city.toUpperCase(),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        meetup.country,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (meetup.telegramLink.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.telegram, size: 14, color: cCyan),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                meetup.telegramLink,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: cCyan,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: cTextTertiary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



