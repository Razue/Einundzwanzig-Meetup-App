import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/meetup.dart';
import 'app_logger.dart';

class MeetupService {
  static const String _url = "https://portal.einundzwanzig.space/api/meetups";

  /// Erste brauchbare Zahl aus mehreren moeglichen Feldnamen.
  /// Das Portal liefert Koordinaten je nach Endpunkt als
  /// 'latitude'/'longitude' ODER 'lat'/'lon'/'lng'.
  static double _firstNum(List<dynamic> candidates) {
    for (final c in candidates) {
      if (c is num) return c.toDouble();
      if (c is String) {
        final v = double.tryParse(c);
        if (v != null) return v;
      }
    }
    return 0.0;
  }

  static Future<List<Meetup>> fetchMeetups() async {
    try {
      final response = await http.get(Uri.parse(_url));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final list = data.map((json) {
          // Bestes verfügbares Bild auswählen (Cover > Image > Logo)
          String image = "";
          if (json['cover'] != null && json['cover'].toString().isNotEmpty) {
            image = json['cover'];
          } else if (json['image'] != null && json['image'].toString().isNotEmpty) {
            image = json['image'];
          } else if (json['logo'] != null && json['logo'].toString().isNotEmpty) {
            image = json['logo'];
          }

          return Meetup(
            id: json['id']?.toString() ?? json['name'] ?? "unknown",
            city: json['city'] ?? json['name'] ?? "Unbekannt",
            country: json['country'] ?? "DE",
            telegramLink: json['url'] ?? "",
            logoUrl: json['logo'] ?? "",
            description: json['intro'] ?? "",
            website: json['website'] ?? "",
            portalLink: json['portalLink'] ?? "",
            twitterUsername: json['twitter_username'] ?? "",
            nostrNpub: json['nostr'] ?? "",
            // ROBUST gegen beide Portal-Feldnamen: die API nutzt teils
            // 'latitude'/'longitude', teils 'lat'/'lon'/'lng'. Wird nur EINE
            // Variante geparst und die API liefert die andere, sind alle
            // Koordinaten 0 -> die "In der Nähe"-Suche findet nichts, weil
            // sie Meetups ohne Koordinaten aussortiert.
            lat: _firstNum([json['latitude'], json['lat']]),
            lng: _firstNum([json['longitude'], json['lon'], json['lng']]),
            coverImagePath: image,
          );
        }).toList();

        // ---- DIAGNOSE: doppelte Eintraege sichtbar machen ----
        // Die App bildet jeden API-Datensatz 1:1 ab und zeigt davon nur die
        // Stadt an. Liefert das Portal zwei Datensaetze fuer denselben Ort
        // (zwei Gruppen ODER ein Altbestand), sehen sie in der Liste
        // identisch aus. Das Log nennt Ross und Reiter.
        final byCity = <String, List<Meetup>>{};
        for (final m in list) {
          byCity.putIfAbsent(m.city.trim().toLowerCase(), () => []).add(m);
        }
        for (final e in byCity.entries) {
          if (e.value.length > 1) {
            AppLogger.diag('Meetups',
                'Stadt "${e.value.first.city}" kommt ${e.value.length}x vom Portal — '
                'IDs: ${e.value.map((m) => m.id).join(", ")}');
          }
        }

        // ---- Nur EXAKTE Doubletten entfernen (identische Portal-ID) ----
        // Zwei verschiedene Gruppen in derselben Stadt bleiben erhalten —
        // das sind echte, unterschiedliche Meetups.
        final seenIds = <String>{};
        final unique = <Meetup>[];
        for (final m in list) {
          if (seenIds.add(m.id)) unique.add(m);
        }
        if (unique.length != list.length) {
          AppLogger.warn('Meetups',
              '${list.length - unique.length} Eintrag/Eintraege mit identischer ID entfernt.');
        }
        return unique;
      } else {
        AppLogger.warn('Meetups', 'Portal antwortete mit HTTP ${response.statusCode}.');
        return [];
      }
    } catch (e) {
      AppLogger.debug('App', "Fehler beim Laden der Meetups: $e");
      return [];
    }
  }
}