import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/guide_service.dart';
import '../l10n/app_localizations.dart';

const _cGuideAccent = Color(0xFFF7931A);
const _cGuideCard = Color(0xFF1E1E1E);

/// Legt die Spotlight-Tour ueber die gesamte App.
///
/// Haengt in MaterialApp.builder, liegt also ueber allen Routen —
/// auch ueber ModalBottomSheets. Genau deshalb muss die Position des
/// Lochs laufend nachgemessen werden: Was unter dem Overlay liegt,
/// aendert sich staendig (Scrollen, Tastatur, oeffnende Sheets).
class GuideOverlay extends StatelessWidget {
  final Widget child;

  const GuideOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Consumer<GuideService>(
          builder: (context, guide, _) {
            final step = guide.currentStep;
            if (!guide.isVisible || step == null) {
              return const SizedBox.shrink();
            }
            // Eigener State pro Schritt: initState uebernimmt das
            // Scrollen zum Ziel und den Neustart der Messung.
            return _GuideSpotlight(
              key: ValueKey('${guide.activeTour}_${guide.currentStepIndex}'),
              guide: guide,
              step: step,
            );
          },
        ),
      ],
    );
  }
}

class _GuideSpotlight extends StatefulWidget {
  final GuideService guide;
  final GuideStep step;

  const _GuideSpotlight({super.key, required this.guide, required this.step});

  @override
  State<_GuideSpotlight> createState() => _GuideSpotlightState();
}

class _GuideSpotlightState extends State<_GuideSpotlight>
    with SingleTickerProviderStateMixin {
  /// Nachmessung. 60 ms ist fein genug, dass das Loch beim Scrollen
  /// mitlaeuft, und grob genug, dass wir nicht jeden Frame neu bauen.
  static const _pollInterval = Duration(milliseconds: 60);

  /// Kurze Anzeige des "Erledigt"-Hakens, bevor automatisch weiter-
  /// geschaltet wird — sonst springt die Tour ohne Rueckmeldung.
  static const _autoAdvanceDelay = Duration(milliseconds: 700);

  Timer? _poll;
  Timer? _advance;
  late final AnimationController _pulse;

  Rect? _hole;
  bool _complete = false;
  bool _timedOut = false;
  bool _didScroll = false;

  /// Ziel existiert, seine Route liegt aber nicht mehr obenauf (ein
  /// Sheet, ein Dialog oder ein anderer Bildschirm liegt darueber).
  bool _covered = false;

  /// Verhindert, dass ein nicht auffindbares Ziel mehrfach
  /// uebersprungen wird.
  bool _skipRequested = false;

  /// Beginn der Wartezeit. Wird zurueckgesetzt, solange das Ziel
  /// verdeckt ist — wer im Plattform-Bildschirm unterwegs ist, soll
  /// seinen Schritt nicht durch Zeitablauf verlieren.
  DateTime _waitingSince = DateTime.now();

  @override
  void initState() {
    super.initState();
    _waitingSince = DateTime.now();

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollTargetIntoView();
      _tick();
    });

    _poll = Timer.periodic(_pollInterval, (_) => _tick());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _advance?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------
  // MESSUNG
  // ---------------------------------------------------------------

  /// Position des Ziel-Widgets, umgerechnet in die Koordinaten des
  /// Overlays. Gibt null zurueck, wenn das Ziel (noch) nicht im Baum
  /// ist oder vollstaendig ausserhalb des Bildschirms liegt.
  Rect? _measure() {
    final key = widget.step.targetKey;
    if (key == null) return null;

    final targetContext = key.currentContext;
    if (targetContext == null) return null;

    final target = targetContext.findRenderObject() as RenderBox?;
    if (target == null || !target.attached || !target.hasSize) return null;

    // Liegt die Route des Ziels noch obenauf? Wenn ein Sheet, ein
    // Dialog oder ein anderer Bildschirm darueber liegt, waere jede
    // Messung ein Loch auf fremdem Inhalt — genau der Fehler, bei dem
    // der Spotlight auf der Staedteliste statt auf dem Nostr-Bereich
    // sass, und der spaeter das Intro-Carousel verdunkelt hat.
    final route = ModalRoute.of(targetContext);
    if (route != null && !route.isCurrent) return null;

    final overlay = context.findRenderObject() as RenderBox?;
    final screen = MediaQuery.of(context).size;

    // Normalfall: in die Koordinaten des Overlays umrechnen. Taugt das
    // eigene RenderObject nicht (noch nicht gebaut, zusammengefallen),
    // greift der Bildschirm als Bezugsrahmen — GuideOverlay haengt im
    // MaterialApp.builder, sein Ursprung ist also der Bildschirmursprung.
    final usable = overlay != null &&
        overlay.attached &&
        overlay.hasSize &&
        overlay.size.width > 1 &&
        overlay.size.height > 1;

    final origin = target.localToGlobal(Offset.zero);
    final topLeft = usable ? overlay.globalToLocal(origin) : origin;
    final bounds = Offset.zero & (usable ? overlay.size : screen);

    var rect = widget.step.holePadding.inflateRect(topLeft & target.size);

    if (!rect.overlaps(bounds)) return null;

    // Auf den sichtbaren Bereich beschneiden — sonst rechnen die
    // Sperrflaechen mit negativen Groessen.
    rect = Rect.fromLTRB(
      math.max(rect.left, 0),
      math.max(rect.top, 0),
      math.min(rect.right, bounds.right),
      math.min(rect.bottom, bounds.bottom),
    );

    if (rect.width <= 1 || rect.height <= 1) return null;
    return rect;
  }

  /// Existiert das Ziel, liegt seine Route aber unter einer anderen?
  bool _isTargetCovered() {
    final targetContext = widget.step.targetKey?.currentContext;
    if (targetContext == null) return false;
    final route = ModalRoute.of(targetContext);
    return route != null && !route.isCurrent;
  }

  void _tick() {
    if (!mounted) return;

    final rect = _measure();
    final covered = _isTargetCovered();

    // Ziel taucht erst spaeter auf (Sheet oeffnet sich) — dann jetzt
    // nachholen, was initState noch nicht konnte.
    if (rect != null && !_didScroll) {
      _didScroll = true;
      _scrollTargetIntoView();
    }

    // Solange verdeckt, laeuft keine Wartezeit.
    if (covered || rect != null) _waitingSince = DateTime.now();

    final complete = widget.step.isComplete;
    final timedOut =
        DateTime.now().difference(_waitingSince) > widget.step.waitTimeout;

    if (rect != _hole ||
        complete != _complete ||
        timedOut != _timedOut ||
        covered != _covered) {
      setState(() {
        _hole = rect;
        _complete = complete;
        _timedOut = timedOut;
        _covered = covered;
      });
    }

    // Ziel bleibt unauffindbar: Schritt ueberspringen statt einen
    // schwarzen Schleier ohne Bezug stehen zu lassen.
    if (widget.step.targetKey != null &&
        rect == null &&
        !covered &&
        timedOut &&
        !_skipRequested) {
      _skipRequested = true;
      widget.guide.skipStep();
      return;
    }

    if (complete && widget.step.autoAdvance && _advance == null) {
      _advance = Timer(_autoAdvanceDelay, () {
        if (mounted) widget.guide.reportStepCompleted();
      });
    }
  }

  Future<void> _scrollTargetIntoView() async {
    if (!widget.step.scrollIntoView) return;
    final targetContext = widget.step.targetKey?.currentContext;
    if (targetContext == null) return;

    final scrollable = Scrollable.maybeOf(targetContext);
    if (scrollable == null) return;

    // Steht das Ziel ohnehin schon im Blick, NICHT scrollen. Sonst
    // ruckelt die Ansicht bei jedem Schritt um ein paar Pixel — und
    // wenn die Tastatur auf- oder zugeht, gleich mehrfach.
    final box = targetContext.findRenderObject() as RenderBox?;
    final viewport = scrollable.context.findRenderObject() as RenderBox?;
    if (box != null && viewport != null && box.hasSize && viewport.hasSize) {
      const margin = 24.0;
      final top = box.localToGlobal(Offset.zero, ancestor: viewport).dy;
      final bottom = top + box.size.height;
      if (top >= margin && bottom <= viewport.size.height - margin) return;
    }

    try {
      await Scrollable.ensureVisible(
        targetContext,
        alignment: 0.35,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } catch (_) {
      // Kein Grund, die Tour daran scheitern zu lassen.
    }
  }

  // ---------------------------------------------------------------
  // AUFBAU
  // ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final step = widget.step;
    final guide = widget.guide;
    final l10n = AppLocalizations.of(context);
    final media = MediaQuery.of(context);
    final hole = _hole;

    // Ein Schritt MIT Ziel zeichnet nur, wenn das Loch auch wirklich
    // sitzt. Ist das Ziel verdeckt (Sheet, Dialog, anderer Bildschirm)
    // oder noch nicht im Baum, bleibt die Tour unsichtbar und wartet.
    //
    // WICHTIG: volle Groesse behalten und NICHT auf SizedBox.shrink
    // zusammenfallen. Sonst waere das eigene RenderObject 0x0, und
    // _measure() koennte nie wieder etwas messen — die Tour saesse fest.
    if (hole == null && step.targetKey != null) {
      return const IgnorePointer(child: SizedBox.expand());
    }

    return Stack(
      children: [
        // 1) Schleier mit Loch — nimmt selbst keine Gesten an.
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) => CustomPaint(
              size: Size.infinite,
              painter: _SpotlightPainter(
                hole: hole,
                radius: step.holeRadius,
                pulse: _pulse.value,
              ),
            ),
          ),
        ),

        // 2) Sperrflaechen rings um das Loch. Alles ausserhalb ist
        //    gesperrt, das Loch bleibt frei — das ist die eigentliche
        //    Freigabe des jeweiligen Bereichs.
        if (step.blockOutside) ..._buildBarriers(hole, media.size),

        // 3) Das Loch selbst. Ein Listener mit translucent nimmt die
        //    Zeiger-Ereignisse entgegen, gibt sie aber an das echte
        //    Widget darunter weiter (hitTest liefert false, deshalb
        //    tastet der Stack weiter nach unten).
        if (hole != null && step.interactiveTarget && step.advanceOnTargetTap)
          Positioned.fromRect(
            rect: hole,
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerUp: (_) => guide.reportTargetTapped(),
              child: const SizedBox.expand(),
            ),
          ),

        // 3b) Ziel nur zeigen, nicht bedienbar.
        if (hole != null && !step.interactiveTarget)
          Positioned.fromRect(
            rect: hole,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: const SizedBox.expand(),
            ),
          ),

        // 4) Tooltip — liegt ueber den Sperrflaechen, seine Knoepfe
        //    funktionieren deshalb immer.
        _buildTooltip(context, guide, l10n, hole, media),

        // 5) Ueberspringen, aber nur wenn es das Loch nicht verdeckt.
        ..._buildSkipButton(context, guide, l10n, hole, media),
      ],
    );
  }

  /// Scrollposition, in der das Ziel-Widget haengt.
  ScrollPosition? _targetScrollPosition() {
    final targetContext = widget.step.targetKey?.currentContext;
    if (targetContext == null) return null;
    return Scrollable.maybeOf(targetContext)?.position;
  }

  /// Wischen auf der Sperrflaeche wird an die darunterliegende
  /// Scrollposition durchgereicht. Ohne das waere jeder Abschnitt, der
  /// hoeher ist als der Bildschirm, waehrend der Tour unerreichbar —
  /// so wie der Nostr-Bereich mit seiner langen Erklaerkarte.
  void _forwardDrag(DragUpdateDetails details) {
    final position = _targetScrollPosition();
    if (position == null) return;
    final next = (position.pixels - details.delta.dy)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    position.jumpTo(next);
  }

  /// Kleiner Nachlauf, damit sich das Wischen nicht abgehackt anfuehlt.
  void _forwardFling(DragEndDetails details) {
    final position = _targetScrollPosition();
    if (position == null) return;
    final velocity = details.velocity.pixelsPerSecond.dy;
    if (velocity.abs() < 200) return;
    final next = (position.pixels - velocity * 0.25)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    position.animateTo(
      next,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  List<Widget> _buildBarriers(Rect? hole, Size size) {
    Widget barrier({
      double? left,
      double? top,
      double? right,
      double? bottom,
      double? width,
      double? height,
    }) {
      return Positioned(
        left: left,
        top: top,
        right: right,
        bottom: bottom,
        width: width,
        height: height,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          onVerticalDragUpdate: _forwardDrag,
          onVerticalDragEnd: _forwardFling,
          child: const SizedBox.expand(),
        ),
      );
    }

    if (hole == null) {
      return [barrier(left: 0, top: 0, right: 0, bottom: 0)];
    }

    return [
      if (hole.top > 0)
        barrier(left: 0, right: 0, top: 0, height: hole.top),
      if (hole.bottom < size.height)
        barrier(left: 0, right: 0, top: hole.bottom, bottom: 0),
      if (hole.left > 0)
        barrier(left: 0, top: hole.top, width: hole.left, height: hole.height),
      if (hole.right < size.width)
        barrier(
          left: hole.right,
          right: 0,
          top: hole.top,
          height: hole.height,
        ),
    ];
  }

  List<Widget> _buildSkipButton(
    BuildContext context,
    GuideService guide,
    AppLocalizations l10n,
    Rect? hole,
    MediaQueryData media,
  ) {
    final top = media.padding.top + 8;
    final chip = Rect.fromLTWH(media.size.width - 172, top, 160, 44);
    if (hole != null && hole.overlaps(chip)) return const [];

    return [
      Positioned(
        top: top,
        right: 12,
        child: Material(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: guide.finishTour,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Text(
                l10n.guideSkip,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildTooltip(
    BuildContext context,
    GuideService guide,
    AppLocalizations l10n,
    Rect? hole,
    MediaQueryData media,
  ) {
    const gap = 16.0;
    final size = media.size;
    final maxWidth = math.min(size.width - 32, 400.0);

    double? top;
    double? bottom;
    double maxHeight = size.height * 0.7;

    if (hole != null) {
      // viewInsets statt padding: bei offener Tastatur ist der Platz
      // unterhalb des Lochs deutlich kleiner, sonst landet der Tooltip
      // hinter der Tastatur.
      final blockedBottom =
          math.max(media.padding.bottom, media.viewInsets.bottom);
      final above = hole.top - media.padding.top - gap;
      final below = size.height - hole.bottom - blockedBottom - gap;

      if (below >= 240 || below >= above) {
        top = hole.bottom + gap;
        maxHeight = below - 8;
      } else {
        bottom = size.height - hole.top + gap;
        maxHeight = above - 8;
      }
      maxHeight = maxHeight.clamp(180.0, size.height * 0.8);
    }

    final card = _buildCard(context, guide, l10n);

    // Ohne Loch (reiner Erklaer-Dialog) mittig — sonst haengt die Karte
    // an der Stack-Ausrichtung und klebt oben links.
    if (hole == null) {
      return Positioned.fill(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: maxHeight,
            ),
            child: SingleChildScrollView(child: card),
          ),
        ),
      );
    }

    return Positioned(
      left: 0,
      right: 0,
      top: top,
      bottom: bottom,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: maxHeight,
          ),
          child: SingleChildScrollView(child: card),
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    GuideService guide,
    AppLocalizations l10n,
  ) {
    final step = widget.step;
    final hint = step.hintKey;
    final canAdvance = step.isComplete;
    // "Erledigt" nur zeigen, wo es auch etwas zu erledigen gab. Ohne
    // Bedingung ist isComplete immer true — der Haken behauptete sonst
    // eine Handlung, die der Nutzer nie ausgefuehrt hat.
    final hintDone = step.completeWhen != null && step.isComplete;

    return Card(
      color: _cGuideCard,
      elevation: 8,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _cGuideAccent, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb, color: _cGuideAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _resolveTitle(l10n, step.titleKey),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l10n.guideStepOf(guide.currentStepIndex + 1, guide.totalSteps),
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
            const SizedBox(height: 10),
            Text(
              _resolveBody(l10n, step.bodyKey),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white70),
            ),
            if (hint != null) ...[
              const SizedBox(height: 14),
              _buildHintRow(l10n, hint, hintDone),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                if (!guide.isFirstStep)
                  TextButton(
                    onPressed: guide.previousStep,
                    child: Text(
                      l10n.guideBack,
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ),
                TextButton(
                  onPressed: guide.finishTour,
                  child: Text(
                    l10n.guideFinishTour,
                    style: const TextStyle(color: Colors.white54),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _cGuideAccent,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.white12,
                    disabledForegroundColor: Colors.white38,
                  ),
                  onPressed: canAdvance ? guide.nextStep : null,
                  child: Text(l10n.actionContinue),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHintRow(AppLocalizations l10n, String hintKey, bool done) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          done ? Icons.check_circle : Icons.touch_app,
          size: 18,
          color: done ? Colors.green : _cGuideAccent,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            done ? l10n.guideStepDone : _resolveHint(l10n, hintKey),
            style: TextStyle(
              color: done ? Colors.green : _cGuideAccent,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------
  // TEXTE
  // ---------------------------------------------------------------

  String _resolveTitle(AppLocalizations l10n, String key) {
    final map = <String, String>{
      'guideOnboardWelcomeTitle': l10n.guideOnboardWelcomeTitle,
      'guideOnboardNicknameTitle': l10n.guideOnboardNicknameTitle,
      'guideOnboardMeetupTitle': l10n.guideOnboardMeetupTitle,
      'guideOnboardMeetupSearchTitle': l10n.guideOnboardMeetupSearchTitle,
      'guideOnboardMeetupPickTitle': l10n.guideOnboardMeetupPickTitle,
      'guideOnboardMeetupConfirmTitle': l10n.guideOnboardMeetupConfirmTitle,
      'guideOnboardNostrTitle': l10n.guideOnboardNostrTitle,
      'guideOnboardPlatformsTitle': l10n.guideOnboardPlatformsTitle,
      'guideOnboardHumanityTitle': l10n.guideOnboardHumanityTitle,
      'guideOnboardSaveTitle': l10n.guideOnboardSaveTitle,
      'guideHomeMeetupTitle': l10n.guideHomeMeetupTitle,
      'guideHomeTrustScoreTitle': l10n.guideHomeTrustScoreTitle,
      'guideHomeReputationTitle': l10n.guideHomeReputationTitle,
      'guideHomeWotTitle': l10n.guideHomeWotTitle,
      'guideHomeCommunityTitle': l10n.guideHomeCommunityTitle,
      'guideHomeEventsTitle': l10n.guideHomeEventsTitle,
      'guideHomeShoutoutTitle': l10n.guideHomeShoutoutTitle,
      'guideHomePodcastTitle': l10n.guideHomePodcastTitle,
      'guideHomeMoreTitle': l10n.guideHomeMoreTitle,
      'guideHomePortalConnectTitle': l10n.guideHomePortalConnectTitle,
      'guideHomeNewsTitle': l10n.guideHomeNewsTitle,
      'guideHomeMyMeetupsTitle': l10n.guideHomeMyMeetupsTitle,
      'guideHomeNearbyTitle': l10n.guideHomeNearbyTitle,
      'guideHomeEventsTabTitle': l10n.guideHomeEventsTabTitle,
      'guideHomeUmrechnerTitle': l10n.guideHomeUmrechnerTitle,
      'guideHomeBitcoinTitle': l10n.guideHomeBitcoinTitle,
      'guideHomeBadgeWalletTitle': l10n.guideHomeBadgeWalletTitle,
      'guideHomeScanTitle': l10n.guideHomeScanTitle,
      'guideHomeSettingsTitle': l10n.guideHomeSettingsTitle,
      'guideHomeGlossaryTitle': l10n.guideHomeGlossaryTitle,
      'guideSettingsBackupTitle': l10n.guideSettingsBackupTitle,
      'guideSettingsLanguageTitle': l10n.guideSettingsLanguageTitle,
      'guideSettingsRelaysTitle': l10n.guideSettingsRelaysTitle,
      'guideSettingsHapticTitle': l10n.guideSettingsHapticTitle,
      'guideSettingsResetTitle': l10n.guideSettingsResetTitle,
      'guideEventsSearchTitle': l10n.guideEventsSearchTitle,
      'guideEventsCalendarTitle': l10n.guideEventsCalendarTitle,
      'guideEventsCardTitle': l10n.guideEventsCardTitle,
      'guideEventsCreateTitle': l10n.guideEventsCreateTitle,
      'guideEvBadgeSwitchTitle': l10n.guideEvBadgeSwitchTitle,
      'guideEvBadgeImageTitle': l10n.guideEvBadgeImageTitle,
      'guideEvBadgeLocationTitle': l10n.guideEvBadgeLocationTitle,
      'guideEvBadgeIssuersTitle': l10n.guideEvBadgeIssuersTitle,
      'guidePortalShoutoutTitle': l10n.guidePortalShoutoutTitle,
      'guidePortalPodcastTitle': l10n.guidePortalPodcastTitle,
      'guidePortalSoundboardTitle': l10n.guidePortalSoundboardTitle,
      'guidePortalMerchTitle': l10n.guidePortalMerchTitle,
      'guidePortalMembershipTitle': l10n.guidePortalMembershipTitle,
      'guidePortalMapTitle': l10n.guidePortalMapTitle,
      'guideWalletBadgesTitle': l10n.guideWalletBadgesTitle,
      'guideWalletShareQrTitle': l10n.guideWalletShareQrTitle,
      'guideWalletExportTitle': l10n.guideWalletExportTitle,
      'guideWalletShareTextTitle': l10n.guideWalletShareTextTitle,
      'guideReputationScoreTitle': l10n.guideReputationScoreTitle,
      'guideReputationLevelTitle': l10n.guideReputationLevelTitle,
      'guideReputationStatsTitle': l10n.guideReputationStatsTitle,
      'guideReputationShareTitle': l10n.guideReputationShareTitle,
      'guideReputationUpdateTitle': l10n.guideReputationUpdateTitle,
    };
    return map[key] ?? key;
  }

  String _resolveBody(AppLocalizations l10n, String key) {
    final map = <String, String>{
      'guideOnboardWelcomeBody': l10n.guideOnboardWelcomeBody,
      'guideOnboardNicknameBody': l10n.guideOnboardNicknameBody,
      'guideOnboardMeetupBody': l10n.guideOnboardMeetupBody,
      'guideOnboardMeetupSearchBody': l10n.guideOnboardMeetupSearchBody,
      'guideOnboardMeetupPickBody': l10n.guideOnboardMeetupPickBody,
      'guideOnboardMeetupConfirmBody': l10n.guideOnboardMeetupConfirmBody,
      'guideOnboardNostrBody': l10n.guideOnboardNostrBody,
      'guideOnboardPlatformsBody': l10n.guideOnboardPlatformsBody,
      'guideOnboardHumanityBody': l10n.guideOnboardHumanityBody,
      'guideOnboardSaveBody': l10n.guideOnboardSaveBody,
      'guideHomeMeetupBody': l10n.guideHomeMeetupBody,
      'guideHomeTrustScoreBody': l10n.guideHomeTrustScoreBody,
      'guideHomeReputationBody': l10n.guideHomeReputationBody,
      'guideHomeWotBody': l10n.guideHomeWotBody,
      'guideHomeCommunityBody': l10n.guideHomeCommunityBody,
      'guideHomeEventsBody': l10n.guideHomeEventsBody,
      'guideHomeShoutoutBody': l10n.guideHomeShoutoutBody,
      'guideHomePodcastBody': l10n.guideHomePodcastBody,
      'guideHomeMoreBody': l10n.guideHomeMoreBody,
      'guideHomePortalConnectBody': l10n.guideHomePortalConnectBody,
      'guideHomeNewsBody': l10n.guideHomeNewsBody,
      'guideHomeMyMeetupsBody': l10n.guideHomeMyMeetupsBody,
      'guideHomeNearbyBody': l10n.guideHomeNearbyBody,
      'guideHomeEventsTabBody': l10n.guideHomeEventsTabBody,
      'guideHomeUmrechnerBody': l10n.guideHomeUmrechnerBody,
      'guideHomeBitcoinBody': l10n.guideHomeBitcoinBody,
      'guideHomeBadgeWalletBody': l10n.guideHomeBadgeWalletBody,
      'guideHomeScanBody': l10n.guideHomeScanBody,
      'guideHomeSettingsBody': l10n.guideHomeSettingsBody,
      'guideHomeGlossaryBody': l10n.guideHomeGlossaryBody,
      'guideSettingsBackupBody': l10n.guideSettingsBackupBody,
      'guideSettingsLanguageBody': l10n.guideSettingsLanguageBody,
      'guideSettingsRelaysBody': l10n.guideSettingsRelaysBody,
      'guideSettingsHapticBody': l10n.guideSettingsHapticBody,
      'guideSettingsResetBody': l10n.guideSettingsResetBody,
      'guideEventsSearchBody': l10n.guideEventsSearchBody,
      'guideEventsCalendarBody': l10n.guideEventsCalendarBody,
      'guideEventsCardBody': l10n.guideEventsCardBody,
      'guideEventsCreateBody': l10n.guideEventsCreateBody,
      'guideEvBadgeSwitchBody': l10n.guideEvBadgeSwitchBody,
      'guideEvBadgeImageBody': l10n.guideEvBadgeImageBody,
      'guideEvBadgeLocationBody': l10n.guideEvBadgeLocationBody,
      'guideEvBadgeIssuersBody': l10n.guideEvBadgeIssuersBody,
      'guidePortalShoutoutBody': l10n.guidePortalShoutoutBody,
      'guidePortalPodcastBody': l10n.guidePortalPodcastBody,
      'guidePortalSoundboardBody': l10n.guidePortalSoundboardBody,
      'guidePortalMerchBody': l10n.guidePortalMerchBody,
      'guidePortalMembershipBody': l10n.guidePortalMembershipBody,
      'guidePortalMapBody': l10n.guidePortalMapBody,
      'guideWalletBadgesBody': l10n.guideWalletBadgesBody,
      'guideWalletShareQrBody': l10n.guideWalletShareQrBody,
      'guideWalletExportBody': l10n.guideWalletExportBody,
      'guideWalletShareTextBody': l10n.guideWalletShareTextBody,
      'guideReputationScoreBody': l10n.guideReputationScoreBody,
      'guideReputationLevelBody': l10n.guideReputationLevelBody,
      'guideReputationStatsBody': l10n.guideReputationStatsBody,
      'guideReputationShareBody': l10n.guideReputationShareBody,
      'guideReputationUpdateBody': l10n.guideReputationUpdateBody,
    };
    return map[key] ?? key;
  }

  String _resolveHint(AppLocalizations l10n, String key) {
    final map = <String, String>{
      'guideHintNickname': l10n.guideHintNickname,
      'guideHintOpenPicker': l10n.guideHintOpenPicker,
      'guideHintSearchCity': l10n.guideHintSearchCity,
      'guideHintStarMeetup': l10n.guideHintStarMeetup,
      'guideHintConfirmSelection': l10n.guideHintConfirmSelection,
      'guideHintNostrKey': l10n.guideHintNostrKey,
      'guideHintSave': l10n.guideHintSave,
      'guideEvBadgeSwitchHint': l10n.guideEvBadgeSwitchHint,
      'guideHintPlatforms': l10n.guideHintPlatforms,
      'guideHintHumanity': l10n.guideHintHumanity,
      'guideHintBackup': l10n.guideHintBackup,
      'guideHomeSettingsBackupHint': l10n.guideHomeSettingsBackupHint,
    };
    return map[key] ?? key;
  }
}

/// Malt den dunklen Schleier und schneidet das Spotlight-Loch heraus.
///
/// saveLayer() erstellt eine eigene Ebene: darauf erst das dunkle
/// Rechteck, dann mit BlendMode.dstOut das Loch — dstOut loescht die
/// Pixel der Ebene an der Stelle des Lochs wieder heraus.
class _SpotlightPainter extends CustomPainter {
  final Rect? hole;
  final double radius;
  final double pulse;

  _SpotlightPainter({
    required this.hole,
    required this.radius,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fullRect = Offset.zero & size;

    canvas.saveLayer(fullRect, Paint());
    canvas.drawRect(
      fullRect,
      Paint()..color = Colors.black.withValues(alpha: 0.85),
    );

    final current = hole;
    if (current != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(current, Radius.circular(radius)),
        Paint()..blendMode = BlendMode.dstOut,
      );
    }

    canvas.restore();

    if (current != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(current, Radius.circular(radius)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 + pulse
          ..color = _cGuideAccent.withValues(alpha: 0.55 + 0.45 * pulse),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) =>
      oldDelegate.hole != hole ||
      oldDelegate.pulse != pulse ||
      oldDelegate.radius != radius;
}
