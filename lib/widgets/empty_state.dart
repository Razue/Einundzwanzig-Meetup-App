import 'package:flutter/material.dart';
import '../theme.dart';
import 'pressable.dart';

/// Leerzustand mit Symbol, Erklaerung und — wo sinnvoll — einem Weg nach vorn.
///
/// Der Unterschied zu einem blossen "Nichts vorhanden": Ein leerer Bildschirm
/// laesst Nutzer im Unklaren, ob etwas kaputt ist oder ob sie selbst am Zug
/// sind. Deshalb hier immer drei Dinge — was fehlt, warum, und was man tun
/// kann. Der Knopf ist optional; wo es nichts zu tun gibt, wird nichts
/// vorgetaeuscht.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color accentColor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.accentColor = cOrange,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PulsingIcon(icon: icon, color: accentColor),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: cText, fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: 0.3),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: cTextSecondary, fontSize: 14, height: 1.5),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 26),
              Pressable(
                onTap: onAction,
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(
                        color: Colors.black, fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Sanft atmendes Symbol. Steht die Systemeinstellung "Animationen
/// reduzieren" an, bleibt es einfach still — kein Sonderfall im Aufrufer.
class _PulsingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;

  const _PulsingIcon({required this.icon, required this.color});

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Erst hier verfuegbar: MediaQuery. Laeuft der Nutzer mit reduzierten
    // Animationen, wird gar nicht erst gestartet.
    if (MediaQuery.of(context).disableAnimations) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _circle(double scale) => Transform.scale(
        scale: scale,
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.10),
            shape: BoxShape.circle,
            border: Border.all(color: widget.color.withValues(alpha: 0.30), width: 1.5),
          ),
          child: Icon(widget.icon, color: widget.color, size: 40),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return _circle(1.0);
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) => _circle(1.0 + (0.06 * _controller.value)),
    );
  }
}
