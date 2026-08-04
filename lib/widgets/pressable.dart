import 'package:flutter/material.dart';

/// Ein Wrapper, der beim Antippen leicht einsinkt und wieder zurueckfedert.
///
/// Warum das mehr ist als Zierrat: Zwischen Fingerdruck und dem Aufbau des
/// naechsten Screens vergehen oft ein paar hundert Millisekunden. Ohne
/// Rueckmeldung wirkt die App in dieser Zeit taub — Nutzer tippen ein
/// zweites Mal. Das Einsinken beantwortet die Beruehrung sofort.
///
/// WICHTIG fuer das Dashboard: Diese Huelle beansprucht bewusst NUR den
/// Tipp-Vorgang. `onLongPress` bleibt frei, damit der Bearbeiten-Modus der
/// Kacheln (langes Druecken) weiterhin von der aeusseren Huelle erkannt
/// wird und die beiden Gesten sich nicht gegenseitig schlucken.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Wie weit die Kachel einsinkt. 0.97 ist spuerbar, ohne zu wackeln.
  final double scaleDownTo;
  final Duration duration;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleDownTo = 0.97,
    this.duration = const Duration(milliseconds: 100),
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      // Schneller zurueck als hinein: Das Loslassen soll sich prompt
      // anfuehlen, nicht traege.
      reverseDuration: const Duration(milliseconds: 80),
    );
    _animation = Tween<double>(begin: 1.0, end: widget.scaleDownTo).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ohne onTap kein Aufwand — dann verhaelt sich die Huelle wie ein
    // gewoehnliches Widget und kostet nichts.
    if (widget.onTap == null && widget.onLongPress == null) return widget.child;

    // Systemweite Einstellung "Animationen reduzieren" respektieren.
    if (MediaQuery.of(context).disableAnimations) {
      return GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        behavior: HitTestBehavior.translucent,
        child: widget.child,
      );
    }

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      behavior: HitTestBehavior.translucent,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (_, child) =>
            Transform.scale(scale: _animation.value, child: child),
        child: widget.child,
      ),
    );
  }
}
