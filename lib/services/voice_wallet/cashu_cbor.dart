import 'dart:convert';
import 'dart:typed_data';

/// CBOR für einen Cashu-V4-Token. Feste Längen, dazu Tags (werden
/// ausgewickelt), negative Zahlen und die einfachen Werte, die in
/// optionalen Feldern vorkommen. Unbekannte Typen werfen.
Object? decodeCbor(Uint8List bytes) {
  final reader = _CborReader(bytes);
  final value = reader.read();
  if (!reader.done) {
    throw const FormatException('Nach dem CBOR-Wert stehen noch Bytes.');
  }
  return value;
}

class _CborReader {
  _CborReader(this.bytes);

  final Uint8List bytes;
  int _i = 0;

  bool get done => _i >= bytes.length;

  Object? read() {
    if (_i >= bytes.length) {
      throw const FormatException('CBOR bricht mitten im Wert ab.');
    }
    final initial = bytes[_i++];
    final major = initial >> 5;
    final info = initial & 0x1f;
    switch (major) {
      case 0:
        return _argument(info);
      case 1:
        return -1 - _argument(info);
      case 2:
        return Uint8List.fromList(_bytes(_argument(info)));
      case 3:
        return utf8.decode(_bytes(_argument(info)));
      case 4:
        final n = _argument(info);
        return List<Object?>.generate(n, (_) => read());
      case 5:
        final n = _argument(info);
        final map = <String, Object?>{};
        for (var i = 0; i < n; i++) {
          final key = read();
          final value = read();
          final name = switch (key) {
            String s => s,
            Uint8List b => utf8.decode(b),
            _ => throw const FormatException('CBOR-Map ohne Textschlüssel.'),
          };
          map[name] = value;
        }
        return map;
      case 6:
        _argument(info);
        return read();
      case 7:
        return _simple(info);
      default:
        throw FormatException('CBOR-Typ $major wird hier nicht gelesen.');
    }
  }

  Object? _simple(int info) {
    if (info == 20) return false;
    if (info == 21) return true;
    if (info == 22 || info == 23) return null;
    if (info == 24) {
      final value = _take(1);
      if (value == 20) return false;
      if (value == 21) return true;
      if (value == 22 || value == 23) return null;
      throw FormatException('CBOR-Wert $value wird hier nicht gelesen.');
    }
    if (info == 27) {
      final data = ByteData(8)..setUint64(0, _take(8));
      return data.getFloat64(0);
    }
    throw FormatException('CBOR-Typ 7 $info wird hier nicht gelesen.');
  }

  int _argument(int info) {
    if (info < 24) return info;
    if (info == 24) return _take(1);
    if (info == 25) return _take(2);
    if (info == 26) return _take(4);
    if (info == 27) return _take(8);
    throw const FormatException('Unbestimmte CBOR-Länge.');
  }

  int _take(int width) {
    if (_i + width > bytes.length) {
      throw const FormatException('CBOR bricht in der Länge ab.');
    }
    var n = 0;
    for (var i = 0; i < width; i++) {
      n = (n << 8) | bytes[_i++];
    }
    return n;
  }

  List<int> _bytes(int length) {
    if (length < 0 || _i + length > bytes.length) {
      throw const FormatException('CBOR-Bytes reichen nicht.');
    }
    final out = bytes.sublist(_i, _i + length);
    _i += length;
    return out;
  }
}
