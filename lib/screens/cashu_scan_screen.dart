import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../theme.dart';

/// Kamera nur, um einen Cashu-Token zu lesen. Der gescannte Text geht
/// zurueck an die Sprachseite — hier wird nichts gespeichert und nichts
/// eingeloest.
class CashuScanScreen extends StatefulWidget {
  const CashuScanScreen({super.key});

  @override
  State<CashuScanScreen> createState() => _CashuScanScreenState();
}

class _CashuScanScreenState extends State<CashuScanScreen> {
  final MobileScannerController _scanner = MobileScannerController();
  bool _done = false;

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    String? fallback;
    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue;
      if (code == null || code.isEmpty) continue;
      fallback ??= code;
      if (code.contains('cashuA') || code.contains('cashuB')) {
        _done = true;
        Navigator.pop(context, code);
        return;
      }
    }
    if (fallback == null) return;
    _done = true;
    Navigator.pop(context, fallback);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      body: Stack(children: [
        MobileScanner(controller: _scanner, onDetect: _onDetect),
        SafeArea(
          child: Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
            ),
          ),
        ),
      ]),
    );
  }
}
