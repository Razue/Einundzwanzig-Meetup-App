import 'dart:convert';

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
    var fallbackScore = -1;
    for (final barcode in capture.barcodes) {
      final code = _barcodeText(barcode);
      if (code == null || code.isEmpty) continue;
      final score = _cashuScore(code);
      if (fallback == null || score > fallbackScore) {
        fallback = code;
        fallbackScore = score;
      }
    }
    if (fallback == null) return;
    _done = true;
    Navigator.pop(context, fallback);
  }

  String? _barcodeText(Barcode barcode) {
    final options = <String>[];
    final raw = barcode.rawValue?.trim();
    if (raw != null && raw.isNotEmpty) options.add(raw);
    final bytes = barcode.rawBytes;
    if (bytes != null && bytes.isNotEmpty) {
      options.add(utf8.decode(bytes, allowMalformed: true));
    }
    String? best;
    var bestScore = -1;
    for (final option in options) {
      final score = _cashuScore(option);
      if (score > bestScore) {
        best = option;
        bestScore = score;
      }
    }
    if (bestScore > 0) return best;
    return options.isEmpty ? null : options.first;
  }

  int _cashuScore(String text) {
    final match = RegExp(r'cashu[ABab]', caseSensitive: false).firstMatch(text);
    if (match == null) return 0;
    return text.length - match.start;
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
