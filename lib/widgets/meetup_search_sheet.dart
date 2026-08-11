import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/meetup.dart';
import '../theme.dart';

/// Suche + Mehrfachauswahl von Meetup-Städten (Favoriten).
///
/// Wird im Profil und im Identity-Setup genutzt. `onDone` liefert die
/// komplette Favoritenliste; der erste Eintrag ist üblicherweise das
/// Home-Meetup.
class MeetupSearchSheet extends StatefulWidget {
  final List<Meetup> meetups;
  final List<String> initialSelected;
  final Function(List<String>) onDone;

  const MeetupSearchSheet({
    super.key,
    required this.meetups,
    this.initialSelected = const [],
    required this.onDone,
  });

  @override
  State<MeetupSearchSheet> createState() => _MeetupSearchSheetState();
}

class _MeetupSearchSheetState extends State<MeetupSearchSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Meetup> _filtered = [];
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _filtered = widget.meetups;
    _selected.addAll(widget.initialSelected);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _filter(String query) {
    if (!mounted) return;
    setState(() {
      _filtered = widget.meetups
          .where((m) => m.city.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).profileSearchCity,
                  prefixIcon: const Icon(Icons.search, color: cOrange),
                  filled: true,
                  fillColor: cDark,
                ),
                onChanged: _filter,
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final meetup = _filtered[index];
                  final active = _selected.contains(meetup.city);
                  return ListTile(
                    title: Text(
                      meetup.city,
                      style: TextStyle(
                        color: active ? cOrange : Colors.white,
                        fontWeight:
                            active ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                    subtitle: (meetup.name.isNotEmpty &&
                            meetup.name.toLowerCase() !=
                                meetup.city.toLowerCase())
                        ? Text(
                            meetup.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: cTextTertiary, fontSize: 11.5),
                          )
                        : null,
                    trailing: Icon(
                      active
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: active ? cOrange : cTextTertiary,
                      size: 26,
                    ),
                    onTap: () {
                      setState(() {
                        if (active) {
                          _selected.remove(meetup.city);
                        } else {
                          _selected.add(meetup.city);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onDone(_selected.toList());
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cOrange,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: Text(
                      '${_selected.length} ★',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
