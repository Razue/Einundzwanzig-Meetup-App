// WEITERE TOUREN
// ============================================
// Badge-Wallet, Community-Bereich, Meine Meetups und Vertrauensnetzwerk.
//
// Alle vier in einer Datei, weil sie sich dieselbe Bauart teilen: wenige
// Schritte, feste Ziele, kein Zustand, keine Bedingungen. Vier Dateien mit
// je zwanzig Zeilen waeren mehr Ablage als Inhalt.
//
// Jede Tour laeuft beim ERSTEN Oeffnen ihres Bildschirms und danach nie
// wieder — es sei denn, jemand setzt sie in den Einstellungen zurueck.
// ============================================

import 'package:flutter/material.dart';
import '../services/guide_service.dart';

/// Kurze Wartezeit fuer Ziele, die je nach Zustand fehlen koennen —
/// eine leere Wallet hat keine Badge-Karte, ein Nicht-Leader keine
/// Verwaltungsknoepfe.
const Duration _optional = Duration(milliseconds: 800);

/// BADGE-WALLET
class WalletTour {
  WalletTour._();

  static final mapKey = GlobalKey(debugLabel: 'guide_w_map');
  static final viewKey = GlobalKey(debugLabel: 'guide_w_view');
  static final shareKey = GlobalKey(debugLabel: 'guide_w_share');
  static final firstBadgeKey = GlobalKey(debugLabel: 'guide_w_badge');

  static List<GuideStep> steps() => [
        GuideStep(
          targetKey: firstBadgeKey,
          titleKey: 'guideWalletBadgesTitle',
          bodyKey: 'guideWalletBadgesBody',
          waitTimeout: _optional,
        ),
        GuideStep(
          targetKey: mapKey,
          titleKey: 'guideWalletMapTitle',
          bodyKey: 'guideWalletMapBody',
          scrollIntoView: false,
        ),
        GuideStep(
          targetKey: viewKey,
          titleKey: 'guideWalletViewTitle',
          bodyKey: 'guideWalletViewBody',
          scrollIntoView: false,
        ),
        GuideStep(
          targetKey: shareKey,
          titleKey: 'guideWalletShareQrTitle',
          bodyKey: 'guideWalletShareQrBody',
          scrollIntoView: false,
        ),
      ];
}

/// COMMUNITY-BEREICH
class CommunityTour {
  CommunityTour._();

  static final portalKey = GlobalKey(debugLabel: 'guide_c_portal');
  static final newsKey = GlobalKey(debugLabel: 'guide_c_news');
  static final shoutoutKey = GlobalKey(debugLabel: 'guide_c_shoutout');
  static final duellKey = GlobalKey(debugLabel: 'guide_c_duell');

  static List<GuideStep> steps() => [
        GuideStep(
          targetKey: portalKey,
          titleKey: 'guideCommunityPortalTitle',
          bodyKey: 'guideCommunityPortalBody',
        ),
        GuideStep(
          targetKey: newsKey,
          titleKey: 'guideCommunityNewsTitle',
          bodyKey: 'guideCommunityNewsBody',
        ),
        GuideStep(
          targetKey: shoutoutKey,
          titleKey: 'guidePortalShoutoutTitle',
          bodyKey: 'guidePortalShoutoutBody',
        ),
        GuideStep(
          targetKey: duellKey,
          titleKey: 'guideCommunityFunTitle',
          bodyKey: 'guideCommunityFunBody',
        ),
      ];
}

/// PORTAL-BEREICH
class PortalAreaTour {
  PortalAreaTour._();

  static final meetupsKey = GlobalKey(debugLabel: 'guide_pa_meetups');
  static final coursesKey = GlobalKey(debugLabel: 'guide_pa_courses');
  static final mapKey = GlobalKey(debugLabel: 'guide_pa_map');
  static final mineKey = GlobalKey(debugLabel: 'guide_pa_mine');

  static List<GuideStep> steps() => [
        GuideStep(
          targetKey: meetupsKey,
          titleKey: 'guidePaMeetupsTitle',
          bodyKey: 'guidePaMeetupsBody',
        ),
        GuideStep(
          targetKey: coursesKey,
          titleKey: 'guidePaCoursesTitle',
          bodyKey: 'guidePaCoursesBody',
        ),
        GuideStep(
          targetKey: mapKey,
          titleKey: 'guidePaMapTitle',
          bodyKey: 'guidePaMapBody',
        ),
        GuideStep(
          targetKey: mineKey,
          titleKey: 'guidePaMineTitle',
          bodyKey: 'guidePaMineBody',
        ),
      ];
}

/// MEINE MEETUPS (Portal-Termine)
class MyMeetupsTour {
  MyMeetupsTour._();

  static final listKey = GlobalKey(debugLabel: 'guide_m_list');

  /// Nur EIN Schritt.
  ///
  /// Der "Termin anlegen"-Knopf sitzt einen Bildschirm tiefer, in der
  /// Verwaltung eines einzelnen Meetups. Ein Schritt darauf haette hier auf
  /// ein Ziel gewartet, das es auf dieser Seite gar nicht gibt — deshalb
  /// steht die Erklaerung dazu im Text des ersten Schritts.
  static List<GuideStep> steps() => [
        GuideStep(
          targetKey: listKey,
          titleKey: 'guideMyMeetupsListTitle',
          bodyKey: 'guideMyMeetupsListBody',
          scrollIntoView: false,
          waitTimeout: _optional,
        ),
      ];
}

/// VERTRAUENSNETZWERK
class WotTour {
  WotTour._();

  static final tabsKey = GlobalKey(debugLabel: 'guide_n_tabs');
  static final refreshKey = GlobalKey(debugLabel: 'guide_n_refresh');

  static List<GuideStep> steps() => [
        GuideStep(
          targetKey: tabsKey,
          titleKey: 'guideWotTabsTitle',
          bodyKey: 'guideWotTabsBody',
          scrollIntoView: false,
        ),
        GuideStep(
          targetKey: refreshKey,
          titleKey: 'guideWotRefreshTitle',
          bodyKey: 'guideWotRefreshBody',
          scrollIntoView: false,
        ),
      ];
}
