// gzip für den Badge-Sync, auf allen Plattformen gleich. dart:io hat
// gzip nativ, der Browser nicht — deshalb hier der eine Ort, der beide
// Seiten auf dasselbe Verfahren bringt.

import 'dart:convert';
import 'dart:typed_data';

import 'badge_sync_codec_io.dart'
    if (dart.library.js_interop) 'badge_sync_codec_web.dart';

class BadgeSyncCodec {
  BadgeSyncCodec._();

  /// Komprimiert [plaintext] mit gzip.
  static Uint8List deflate(String plaintext) =>
      badgeSyncDeflate(utf8.encode(plaintext));

  /// Kehrt [deflate] um. Wirft bei kaputten Daten.
  static String inflate(Uint8List data) => utf8.decode(badgeSyncInflate(data));
}

