import 'package:flutter/widgets.dart';

/// Ankerpunkt für das Teilen-Blatt von share_plus.
///
/// iOS verlangt ein nicht-leeres `sharePositionOrigin`, das vollständig
/// innerhalb der Ansicht liegt, sobald UIKit das Teilen als Popover
/// darstellt. share_plus 10.x tat das ab iOS 26 auch auf dem iPhone und
/// warf ohne gültigen Anker (Issue #73). Ab 13.3.1 gilt der Popover nur
/// noch auf dem iPad, der keyWindow-Fallback ist weg. Der Anker bleibt,
/// damit das Blatt am auslösenden Element sitzt und nicht in der Mitte.
///
/// Aufrufen unmittelbar vor `Share`, solange der Kontext noch gebaut ist.
/// Nach einem `await` zuerst prüfen, ob er noch steht. Ein früher
/// festgehaltenes Rechteck liegt nach einer Drehung außerhalb der Ansicht.
///
/// Ein Widget in einem scrollbaren Sheet kann größer als die Ansicht sein
/// oder nach dem Scrollen teilweise darüber hinausragen. Zurückgegeben wird
/// deshalb nur der Ausschnitt, der in der Ansicht liegt.
Rect shareOriginFor(BuildContext context) {
  final screen = _screenRect(context);
  final renderObject = context.findRenderObject();
  final renderBox = renderObject is RenderBox ? renderObject : null;
  if (renderBox != null &&
      renderBox.hasSize &&
      renderBox.size.width > 0 &&
      renderBox.size.height > 0) {
    final clipped = (renderBox.localToGlobal(Offset.zero) & renderBox.size)
        .intersect(screen);
    if (clipped.width > 0 && clipped.height > 0) return clipped;
  }
  // Komplett außerhalb oder noch nicht gelegt: die Bildschirmfläche ist ein
  // gültiger Anker, {{0,0},{0,0}} nicht. Auf dem iPad ergibt das ein
  // zentriertes Popover.
  return screen;
}

Rect _screenRect(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  if (size.width <= 0 || size.height <= 0) {
    return const Rect.fromLTWH(0, 0, 1, 1);
  }
  return Offset.zero & size;
}
