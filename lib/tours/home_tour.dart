import 'package:flutter/material.dart';
import '../services/guide_service.dart';

class HomeTour {
  HomeTour._();

  /// Kacheln, die sich in den Einstellungen ausblenden lassen, bekommen
  /// eine kurze Wartezeit: Ist die Kachel weg, ueberspringt das Overlay
  /// den Schritt nach 1,2 Sekunden, statt sechs Sekunden zu warten.
  /// 220 ms statt 500. Bei mehreren ausgeblendeten Kacheln hintereinander
  /// summierte sich das frueher zu Pausen von ueber einer Sekunde, in denen
  /// der Bildschirm einfach nur dunkel war. So kurz wie moeglich, aber nicht
  /// null: Ein Ziel braucht einen Frame, um im Baum zu erscheinen.
  static const _optionalTile = Duration(milliseconds: 220);

  // --- Untere Leiste ---
  static final homeTabKey = GlobalKey(debugLabel: 'guide_home_tab');
  static final badgeTabKey = GlobalKey(debugLabel: 'guide_badge_tab');
  static final communityTabKey = GlobalKey(debugLabel: 'guide_community_tab');
  // "In der Nähe" hat den Community-Platz in der unteren Leiste
  // uebernommen; communityTabKey bleibt fuer den Fall, dass der
  // Community-Tab zurueckkehrt.
  static final nearbyTabKey = GlobalKey(debugLabel: 'guide_nearby_tab');
  static final eventsTabKey = GlobalKey(debugLabel: 'guide_events_tab');
  static final scanFabKey = GlobalKey(debugLabel: 'guide_scan_fab');

  // --- Kacheln (werden im HomeScreen gesetzt) ---
  static final trustScoreKey = GlobalKey(debugLabel: 'guide_trust_score');
  static final homeMeetupKey = GlobalKey(debugLabel: 'guide_home_meetup_card');
  static final reputationKey = GlobalKey(debugLabel: 'guide_reputation');
  static final communityKey = GlobalKey(debugLabel: 'guide_community_tile');
  static final wotKey = GlobalKey(debugLabel: 'guide_wot');
  static final eventsKey = GlobalKey(debugLabel: 'guide_events_tile');
  static final shoutoutKey = GlobalKey(debugLabel: 'guide_shoutout');
  static final podcastKey = GlobalKey(debugLabel: 'guide_podcast');
  static final portalConnectKey = GlobalKey(debugLabel: 'guide_portal_connect');
  static final umrechnerKey = GlobalKey(debugLabel: 'guide_umrechner');
  static final bitcoinKey = GlobalKey(debugLabel: 'guide_bitcoin');
  static final newsKey = GlobalKey(debugLabel: 'guide_news');
  static final myMeetupsKey = GlobalKey(debugLabel: 'guide_my_meetups');
  static final settingsKey = GlobalKey(debugLabel: 'guide_settings');
  static final customizeKey = GlobalKey(debugLabel: 'guide_customize');
  static final glossaryKey = GlobalKey(debugLabel: 'guide_glossary');

  /// Reihenfolge folgt der Kachel-Definition im HomeScreen, damit die
  /// Tour von oben nach unten durchlaeuft und nicht hin und her
  /// springt. Die Bedienelemente der unteren Leiste kommen zuletzt.
  static List<GuideStep> steps() => [
        // 0 — Nachschlagen. Steht bewusst GANZ VORN: Wer die Tour gleich
        //     wegtippt, hat wenigstens dieses eine gesehen — und findet
        //     alles Weitere selbst.
        GuideStep(
          targetKey: glossaryKey,
          titleKey: 'guideHomeGlossaryTitle',
          bodyKey: 'guideHomeGlossaryBody',
          scrollIntoView: false,
        ),

        // 1 — Trust Score. Die Kachel ist seit der Kopfzeilen-Umstellung bei
        //     den meisten ausgeblendet, deshalb die kurze Wartezeit: Ist sie
        //     nicht da, geht die Tour zuegig weiter statt sekundenlang zu
        //     warten.
        GuideStep(
          targetKey: trustScoreKey,
          titleKey: 'guideHomeTrustScoreTitle',
          bodyKey: 'guideHomeTrustScoreBody',
          waitTimeout: _optionalTile,
        ),

        // 2 — Home-Meetup
        GuideStep(
          targetKey: homeMeetupKey,
          titleKey: 'guideHomeMeetupTitle',
          bodyKey: 'guideHomeMeetupBody',
        ),

        // 3 — Reputation
        GuideStep(
          targetKey: reputationKey,
          titleKey: 'guideHomeReputationTitle',
          bodyKey: 'guideHomeReputationBody',
          waitTimeout: _optionalTile,
        ),

        // 4 — Community
        GuideStep(
          targetKey: communityKey,
          titleKey: 'guideHomeCommunityTitle',
          bodyKey: 'guideHomeCommunityBody',
          waitTimeout: _optionalTile,
        ),

        // 5 — Vertrauensnetzwerk
        GuideStep(
          targetKey: wotKey,
          titleKey: 'guideHomeWotTitle',
          bodyKey: 'guideHomeWotBody',
          waitTimeout: _optionalTile,
        ),

        // 6 — Events
        GuideStep(
          targetKey: eventsKey,
          titleKey: 'guideHomeEventsTitle',
          bodyKey: 'guideHomeEventsBody',
          waitTimeout: _optionalTile,
        ),

        // 7 — Shoutout
        GuideStep(
          targetKey: shoutoutKey,
          titleKey: 'guideHomeShoutoutTitle',
          bodyKey: 'guideHomeShoutoutBody',
          waitTimeout: _optionalTile,
        ),

        // 8 — Podcast
        GuideStep(
          targetKey: podcastKey,
          titleKey: 'guideHomePodcastTitle',
          bodyKey: 'guideHomePodcastBody',
          waitTimeout: _optionalTile,
        ),

        // 9 — Sammelschritt fuer SatoshiDuell, Portal-Bereich, PlebRap
        //     und Nostr. BEWUSST ohne Ziel: Vier Kacheln lassen sich
        //     nicht mit einem Loch markieren, und derselbe GlobalKey an
        //     vier Widgets waere zur Laufzeit ein Fehler.
        const GuideStep(
          titleKey: 'guideHomeMoreTitle',
          bodyKey: 'guideHomeMoreBody',
          tooltipAlignment: Alignment.center,
        ),

        // 10 — Portal-Verbindung
        GuideStep(
          targetKey: portalConnectKey,
          titleKey: 'guideHomePortalConnectTitle',
          bodyKey: 'guideHomePortalConnectBody',
          waitTimeout: _optionalTile,
        ),

        // 11 — Umrechner
        GuideStep(
          targetKey: umrechnerKey,
          titleKey: 'guideHomeUmrechnerTitle',
          bodyKey: 'guideHomeUmrechnerBody',
          waitTimeout: _optionalTile,
        ),

        // 12 — Bitcoin-Kurs
        GuideStep(
          targetKey: bitcoinKey,
          titleKey: 'guideHomeBitcoinTitle',
          bodyKey: 'guideHomeBitcoinBody',
          waitTimeout: _optionalTile,
        ),

        // 13 — News
        GuideStep(
          targetKey: newsKey,
          titleKey: 'guideHomeNewsTitle',
          bodyKey: 'guideHomeNewsBody',
          waitTimeout: _optionalTile,
        ),

        // 14 — Meine Meetups
        GuideStep(
          targetKey: myMeetupsKey,
          titleKey: 'guideHomeMyMeetupsTitle',
          bodyKey: 'guideHomeMyMeetupsBody',
          waitTimeout: _optionalTile,
        ),

        // --- Untere Leiste. Kein ensureVisible noetig: Die Knoepfe
        //     haengen in keiner Scrollflaeche.
        // 14b — Dashboard anpassen. Steht direkt nach den Kacheln und vor
        //       der unteren Leiste: Wer gerade neunzehn Kacheln gesehen hat,
        //       ist genau jetzt bereit fuer "das musst du dir nicht alles
        //       antun".
        GuideStep(
          targetKey: customizeKey,
          titleKey: 'guideHomeCustomizeTitle',
          bodyKey: 'guideHomeCustomizeBody',
          waitTimeout: _optionalTile,
        ),

        // 15 — Badge-Wallet
        GuideStep(
          targetKey: badgeTabKey,
          titleKey: 'guideHomeBadgeWalletTitle',
          bodyKey: 'guideHomeBadgeWalletBody',
          scrollIntoView: false,
        ),

        // 16 — In der Nähe
        GuideStep(
          targetKey: nearbyTabKey,
          titleKey: 'guideHomeNearbyTitle',
          bodyKey: 'guideHomeNearbyBody',
          scrollIntoView: false,
        ),

        // 17 — Scan-Knopf. Rundes Loch, damit es zum runden Knopf passt.
        GuideStep(
          targetKey: scanFabKey,
          titleKey: 'guideHomeScanTitle',
          bodyKey: 'guideHomeScanBody',
          scrollIntoView: false,
          holePadding: EdgeInsets.all(6),
          holeRadius: 40,
        ),

        // 18 — Event-Bereich
        GuideStep(
          targetKey: eventsTabKey,
          titleKey: 'guideHomeEventsTabTitle',
          bodyKey: 'guideHomeEventsTabBody',
          scrollIntoView: false,
        ),

        // 19 — Einstellungen, mit Vorausweis aufs Backup.
        GuideStep(
          targetKey: settingsKey,
          titleKey: 'guideHomeSettingsTitle',
          bodyKey: 'guideHomeSettingsBody',
          hintKey: 'guideHomeSettingsBackupHint',
          scrollIntoView: false,
        ),
      ];
}
