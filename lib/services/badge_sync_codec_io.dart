// dart:io-Seite des Badge-Sync-Codec: natives gzip.

import 'dart:io' as io;
import 'dart:typed_data';

Uint8List badgeSyncDeflate(List<int> bytes) =>
    Uint8List.fromList(io.gzip.encode(bytes));

List<int> badgeSyncInflate(Uint8List data) => io.gzip.decode(data);
