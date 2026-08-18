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

  /// Ziele im oberen Teil des Editors — sie stehen IMMER im Baum, egal ob
  /// jemand Badges vergeben darf.
  static final basicsKey = GlobalKey(debugLabel: 'guide_evb_basics');
  static final whenWhereKey = GlobalKey(debugLabel: 'guide_evb_whenwhere');

  /// Die Schritte.
  ///
  /// [mayCreateBadge] entscheidet, ob der Badge-Teil ueberhaupt vorkommt.
  /// Wer nicht berechtigt ist, kann den Schalter nicht bedienen — ihn dann
  /// zu erklaeren oder gar dazu aufzufordern waere schlicht falsch.
  ///
  /// Und der Schalter-Schritt haelt NICHT mehr an, bis er umgelegt ist.
  /// Diese Bedingung war ein Fehler: Wer einen gewoehnlichen Termin ohne
  /// Badge anlegt, kam damit nicht weiter — die Tour verlangte etwas, das
  /// er gar nicht wollte. Die Folgeschritte warten stattdessen kurz auf
  /// ihre Ziele und werden uebersprungen, wenn der Schalter aus bleibt.
  static List<GuideStep> steps({bool mayCreateBadge = false}) => [
        GuideStep(
          targetKey: basicsKey,
          titleKey: 'guideEvBasicsTitle',
          bodyKey: 'guideEvBasicsBody',
        ),
        GuideStep(
          targetKey: whenWhereKey,
          titleKey: 'guideEvWhenWhereTitle',
          bodyKey: 'guideEvWhenWhereBody',
        ),
        if (mayCreateBadge) ...[
          GuideStep(
            targetKey: switchKey,
            titleKey: 'guideEvBadgeSwitchTitle',
            bodyKey: 'guideEvBadgeSwitchBody',
            hintKey: 'guideEvBadgeSwitchHint',
          ),
          // Kurze Wartezeit: Bleibt der Schalter aus, gibt es diese Ziele
          // nicht — dann soll die Tour zuegig darueber hinweggehen statt
          // sekundenlang auf etwas zu warten, das nie kommt.
          GuideStep(
            targetKey: imageKey,
            titleKey: 'guideEvBadgeImageTitle',
            bodyKey: 'guideEvBadgeImageBody',
            waitForTarget: true,
            waitTimeout: _optionalStep,
          ),
          GuideStep(
            targetKey: locationKey,
            titleKey: 'guideEvBadgeLocationTitle',
            bodyKey: 'guideEvBadgeLocationBody',
            waitForTarget: true,
            waitTimeout: _optionalStep,
          ),
          GuideStep(
            targetKey: issuersKey,
            titleKey: 'guideEvBadgeIssuersTitle',
            bodyKey: 'guideEvBadgeIssuersBody',
            waitForTarget: true,
            waitTimeout: _optionalStep,
          ),
        ],
      ];

  static const Duration _optionalStep = Duration(milliseconds: 900);
}
