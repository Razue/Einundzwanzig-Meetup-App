import 'package:flutter/material.dart';
import '../services/meetup_calendar_service.dart';

/// Das Wappen des Meetups als Wasserzeichen hinter der generativen Grafik.
///
/// Warum das mehr ist als Zierrat: Bisher sahen alle Badges gleich aus —
/// dieselbe Grafik, nur mit anderem Startwert. Das Wappen macht jedes Badge
/// auf den ersten Blick zuordenbar, ohne dass man den Namen lesen muss. Und
/// es verbindet das Badge sichtbar mit der Gemeinschaft, aus der es stammt.
///
/// AUSFALLSICHER: Gibt es kein Wappen — weil das Portal keines liefert, das
/// Bild nicht laedt oder man offline ist —, bleibt schlicht nichts uebrig
/// und die generative Grafik darunter traegt die Karte allein. Niemals ein
/// leerer Kasten oder ein kaputtes Bildsymbol.
class MeetupCrestWatermark extends StatelessWidget {
  /// Meetup-Name aus dem Badge, Form "Stadt, LAND".
  final String meetupName;

  /// Deckkraft. Zurueckhaltend, damit Titel und Datum lesbar bleiben.
  final double opacity;

  /// Anteil der Kartenbreite, den das Wappen einnimmt.
  final double widthFactor;

  const MeetupCrestWatermark({
    super.key,
    required this.meetupName,
    this.opacity = 0.20,
    this.widthFactor = 1.05,
  });

  @override
  Widget build(BuildContext context) {
    // Der Badge-Name traegt das Land hinten dran — fuer die Wappen-Suche
    // zaehlt nur der Teil davor.
    final city = meetupName.split(',').first.trim();
    if (city.isEmpty) return const SizedBox.shrink();

    final url = MeetupCalendarService.absoluteImageUrl(
      MeetupCalendarService.logoFor(city),
    );
    if (url.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, c) {
        final side = c.maxWidth * widthFactor;
        return Align(
          alignment: const Alignment(0.15, -0.25),
          child: Opacity(
            opacity: opacity,
            // WEICH AUSLAUFENDE KANTEN: Ohne die Maske sass das Wappen als
            // hart begrenztes Rechteck auf der Karte und wirkte aufgeklebt.
            // Der radiale Verlauf laesst es zum Rand hin verschwinden, so
            // dass es mit der generativen Grafik darunter verschmilzt.
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (rect) => const RadialGradient(
                center: Alignment.center,
                radius: 0.62,
                colors: [
                  Colors.white,
                  Colors.white,
                  Colors.transparent,
                ],
                stops: [0.0, 0.55, 1.0],
              ).createShader(rect),
              child: Image.network(
                url,
                width: side,
                height: side,
                fit: BoxFit.contain,
                // Kein Platzhalter waehrend des Ladens: Ein aufblitzender
                // Kasten waere stoerender als das spaetere Erscheinen.
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : const SizedBox.shrink(),
                errorBuilder: (_, error, stack) => const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Das Wappen als eigenstaendiges Bildelement — ohne Daempfung, ohne
/// Positionierung. Gedacht fuer Stellen, an denen es NICHT Hintergrund ist,
/// sondern selbst das Motiv: etwa im Medaillon der Badge-Detailansicht.
///
/// Faellt auf [fallback] zurueck, wenn kein Wappen vorliegt oder das Bild
/// nicht laedt — dort steht dann wieder das gewohnte Symbol.
class MeetupCrestFace extends StatelessWidget {
  final String meetupName;
  final Widget fallback;

  const MeetupCrestFace({
    super.key,
    required this.meetupName,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final city = meetupName.split(',').first.trim();
    if (city.isEmpty) return fallback;

    final url = MeetupCalendarService.absoluteImageUrl(
      MeetupCalendarService.logoFor(city),
    );
    if (url.isEmpty) return fallback;

    return Image.network(
      url,
      fit: BoxFit.contain,
      // Waehrend des Ladens das gewohnte Symbol zeigen statt einer Luecke —
      // die Karte soll nie halbfertig wirken.
      loadingBuilder: (_, child, progress) => progress == null ? child : fallback,
      errorBuilder: (_, error, stack) => fallback,
    );
  }
}
