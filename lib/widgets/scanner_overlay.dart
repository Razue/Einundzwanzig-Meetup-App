import 'package:flutter/material.dart';
import '../theme.dart';

/// Überlagerung für die Kamera-Ansicht: abgedunkelter Rand, freies Fenster
/// in der Mitte, Eckwinkel und eine wandernde Suchlinie.
///
/// Der Nutzen ist handfest, nicht dekorativ: Ohne Rahmen weiß niemand, wie
/// weit weg der Code sein darf oder ob die App überhaupt sucht. Beides
/// führt dazu, dass Leute zu nah herangehen und der Code unscharf wird.
/// Das freie Fenster gibt die Zielgröße vor, die Linie zeigt Aktivität.
class ScannerOverlay extends StatefulWidget {
  /// Kantenlänge des freien Fensters.
  final double windowSize;

  /// Farbe von Winkeln und Suchlinie.
  final Color accent;

  const ScannerOverlay({
    super.key,
    this.windowSize = 260,
    this.accent = cOrange,
  });

  @override
  State<ScannerOverlay> createState() => _ScannerOverlayState();
}

class _ScannerOverlayState extends State<ScannerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Bei reduzierten Animationen steht die Linie still — der Rahmen
    // allein erfuellt seinen Zweck weiterhin.
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

  @override
  Widget build(BuildContext context) {
    final size = widget.windowSize;

    return IgnorePointer(
      child: Stack(children: [
        // Abdunklung mit ausgespartem Fenster.
        Positioned.fill(
          child: ColorFiltered(
            colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcOut),
            child: Stack(children: [
              // Der Vollflächen-Container wird durch srcOut zur Maske.
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ]),
          ),
        ),

        // Eckwinkel und Suchlinie.
        Center(
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(children: [
              _corner(Alignment.topLeft, true, true),
              _corner(Alignment.topRight, true, false),
              _corner(Alignment.bottomLeft, false, true),
              _corner(Alignment.bottomRight, false, false),
              AnimatedBuilder(
                animation: _controller,
                builder: (_, __) => Positioned(
                  top: 12 + (size - 24) * _controller.value,
                  left: 14,
                  right: 14,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        widget.accent.withValues(alpha: 0.0),
                        widget.accent,
                        widget.accent.withValues(alpha: 0.0),
                      ]),
                      boxShadow: [
                        BoxShadow(
                            color: widget.accent.withValues(alpha: 0.55),
                            blurRadius: 9),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _corner(Alignment a, bool top, bool left) {
    const len = 30.0;
    const thick = 3.0;
    final side = BorderSide(color: widget.accent, width: thick);
    return Align(
      alignment: a,
      child: Container(
        width: len,
        height: len,
        decoration: BoxDecoration(
          border: Border(
            top: top ? side : BorderSide.none,
            bottom: top ? BorderSide.none : side,
            left: left ? side : BorderSide.none,
            right: left ? BorderSide.none : side,
          ),
          borderRadius: BorderRadius.only(
            topLeft: top && left ? const Radius.circular(18) : Radius.zero,
            topRight: top && !left ? const Radius.circular(18) : Radius.zero,
            bottomLeft: !top && left ? const Radius.circular(18) : Radius.zero,
            bottomRight: !top && !left ? const Radius.circular(18) : Radius.zero,
          ),
        ),
      ),
    );
  }
}
