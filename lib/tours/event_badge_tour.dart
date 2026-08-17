// TOUR: EVENT-BADGES
// ============================================
// Die Event-Badges sind nach dem urspruenglichen Guide entstanden und
// deshalb nirgends erklaert. Sie sind aber der Teil mit den meisten
// unsichtbaren Regeln — Ortsbindung, Zeitfenster, Ausstellerliste —, und
// wer die nicht kennt, legt ein Event an, bei dem am Veranstaltungstag
// niemand ein Badge bekommt.
//
// Die Tour laeuft IM Termin-Editor und nur fuer Leute, die ueberhaupt
// Badges vergeben duerfen. Wer den Schalter gar nicht bedienen kann,
// braucht auch keine Erklaerung dazu.
// ============================================

import 'package:flutter/material.dart';
import '../services/guide_service.dart';

class EventBadgeTour {
  EventBadgeTour._();

  static final switchKey = GlobalKey(debugLabel: 'guide_evb_switch');
  static final imageKey = GlobalKey(debugLabel: 'guide_evb_image');
  static final locationKey = GlobalKey(debugLabel: 'guide_evb_location');
  static final issuersKey = GlobalKey(debugLabel: 'guide_evb_issuers');

  /// [badgeOn] meldet, ob der Schalter bereits umgelegt ist. Die folgenden
  /// Felder erscheinen erst dann im Baum — ohne diese Bedingung stuende die
  /// Tour vor Zielen, die es noch gar nicht gibt.
  static List<GuideStep> steps({ValueGetter<bool>? badgeOn}) => [
        GuideStep(
          targetKey: switchKey,
          titleKey: 'guideEvBadgeSwitchTitle',
          bodyKey: 'guideEvBadgeSwitchBody',
          hintKey: 'guideEvBadgeSwitchHint',
          completeWhen: badgeOn,
          autoAdvance: true,
        ),
        GuideStep(
          targetKey: imageKey,
          titleKey: 'guideEvBadgeImageTitle',
          bodyKey: 'guideEvBadgeImageBody',
          waitForTarget: true,
        ),
        GuideStep(
          targetKey: locationKey,
          titleKey: 'guideEvBadgeLocationTitle',
          bodyKey: 'guideEvBadgeLocationBody',
          waitForTarget: true,
        ),
        GuideStep(
          targetKey: issuersKey,
          titleKey: 'guideEvBadgeIssuersTitle',
          bodyKey: 'guideEvBadgeIssuersBody',
          waitForTarget: true,
        ),
      ];
}
