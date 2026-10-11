// Browser-Seite des Badge-Sync-Codec: reines Dart-Deflate aus archive.

import 'dart:typed_data';

import 'package:archive/archive.dart';

Uint8List badgeSyncDeflate(List<int> bytes) =>
    Uint8List.fromList(GZipEncoder().encodeBytes(bytes));

List<int> badgeSyncInflate(Uint8List data) => GZipDecoder().decodeBytes(data);
